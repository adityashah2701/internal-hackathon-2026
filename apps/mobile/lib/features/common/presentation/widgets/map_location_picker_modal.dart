import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';

/// Accurate Web Mercator projection calculations for real Slippy Map tiles
abstract final class MercatorProjection {
  static const double tileSize = 256.0;

  static double getTileCount(double zoom) => math.pow(2.0, zoom).toDouble();

  /// Converts lat/lng coordinates into continuous world pixel coordinates
  static Offset latLngToWorldPixels(double lat, double lng, double zoom) {
    final double n = getTileCount(zoom);
    final double x = ((lng + 180.0) / 360.0) * n * tileSize;

    final double latRad = lat * math.pi / 180.0;
    // Clamping to avoid singularity at poles
    final double clampedLatRad = latRad.clamp(-1.4844, 1.4844);
    final double y =
        (1.0 - math.log(math.tan(clampedLatRad) + 1.0 / math.cos(clampedLatRad)) / math.pi) /
            2.0 *
            n *
            tileSize;

    return Offset(x, y);
  }

  /// Converts continuous world pixel coordinates back to lat/lng
  static ({double lat, double lng}) worldPixelsToLatLng(Offset worldPixels, double zoom) {
    final double n = getTileCount(zoom);
    final double lng = (worldPixels.dx / (n * tileSize)) * 360.0 - 180.0;

    final double m = math.pi - (2.0 * math.pi * worldPixels.dy) / (n * tileSize);
    final double sinhM = (math.exp(m) - math.exp(-m)) / 2.0;
    final double latRad = math.atan(sinhM);
    final double lat = latRad * 180.0 / math.pi;

    return (
      lat: lat.clamp(-85.0511, 85.0511),
      lng: ((lng + 180.0) % 360.0) - 180.0,
    );
  }
}

class PickedLocationResult {
  const PickedLocationResult({
    required this.address,
    required this.houseFlatNumber,
    required this.buildingName,
    required this.landmark,
    required this.fullFormattedAddress,
    required this.latitude,
    required this.longitude,
    required this.locality,
  });

  /// Street / Locality resolved by map pin
  final String address;

  /// Specific unit details added by user for worker dispatch
  final String houseFlatNumber;
  final String buildingName;
  final String landmark;

  /// Complete combined address that worker sees on their job card
  final String fullFormattedAddress;

  final double latitude;
  final double longitude;
  final String locality;
}

class LocationSuggestion {
  const LocationSuggestion({
    required this.displayName,
    required this.name,
    required this.lat,
    required this.lon,
  });

  final String displayName;
  final String name;
  final double lat;
  final double lon;
}

/// Uber-style Interactive Map Location Picker
/// Features:
/// 1. Automatic initial fetch of user's current GPS location on open
/// 2. Pin placed on accurate location
/// 3. User can freely pan/drag the map to adjust the pin
/// 4. Live OpenStreetMap Nominatim reverse geocoding on drag stop
/// 5. Live autocomplete suggestions as user types
/// 6. Exact address breakdown (House/Flat No, Apartment/Building Name, Landmark)
///    so worker can navigate directly to the door.
class MapLocationPickerModal extends StatefulWidget {
  const MapLocationPickerModal({
    super.key,
    this.initialAddress = '',
    this.initialHouseFlat = '',
    this.initialBuilding = '',
    this.initialLandmark = '',
    this.initialLat = 18.5204, // Default to Pune, Maharashtra
    this.initialLng = 73.8567,
    this.autoFetchCurrentLocation = true,
  });

  final String initialAddress;
  final String initialHouseFlat;
  final String initialBuilding;
  final String initialLandmark;
  final double initialLat;
  final double initialLng;
  final bool autoFetchCurrentLocation;

  static Future<PickedLocationResult?> show(
    BuildContext context, {
    String initialAddress = '',
    String initialHouseFlat = '',
    String initialBuilding = '',
    String initialLandmark = '',
    double initialLat = 18.5204,
    double initialLng = 73.8567,
    bool autoFetchCurrentLocation = true,
  }) {
    return showModalBottomSheet<PickedLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => MapLocationPickerModal(
        initialAddress: initialAddress,
        initialHouseFlat: initialHouseFlat,
        initialBuilding: initialBuilding,
        initialLandmark: initialLandmark,
        initialLat: initialLat,
        initialLng: initialLng,
        autoFetchCurrentLocation: autoFetchCurrentLocation,
      ),
    );
  }

  @override
  State<MapLocationPickerModal> createState() => _MapLocationPickerModalState();
}

class _MapLocationPickerModalState extends State<MapLocationPickerModal>
    with SingleTickerProviderStateMixin {
  late double _latitude;
  late double _longitude;

  late final TextEditingController _streetAddressController;
  late final TextEditingController _houseFlatController;
  late final TextEditingController _buildingController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _searchController;

  bool _isLoadingGps = false;
  bool _isReverseGeocoding = false;
  bool _isSearching = false;
  bool _isDraggingMap = false;
  double _zoom = 16.0;

  String _selectedLocality = 'Detecting Location...';
  List<LocationSuggestion> _suggestions = <LocationSuggestion>[];
  Timer? _searchDebounce;
  Timer? _dragDebounce;

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1.0).clamp(11.0, 18.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1.0).clamp(11.0, 18.0);
    });
  }

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLat;
    _longitude = widget.initialLng;

    _streetAddressController = TextEditingController(text: widget.initialAddress);
    _houseFlatController = TextEditingController(text: widget.initialHouseFlat);
    _buildingController = TextEditingController(text: widget.initialBuilding);
    _landmarkController = TextEditingController(text: widget.initialLandmark);
    _searchController = TextEditingController();

    // Automatically fetch user's current GPS location on first load!
    if (widget.autoFetchCurrentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchCurrentGpsLocation();
      });
    } else if (widget.initialAddress.isNotEmpty) {
      _selectedLocality = widget.initialAddress.split(',').first;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _dragDebounce?.cancel();
    _streetAddressController.dispose();
    _houseFlatController.dispose();
    _buildingController.dispose();
    _landmarkController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================================
  // 1. REVERSE GEOCODING (OpenStreetMap Nominatim API)
  // =========================================================================
  Future<void> _reverseGeocode(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _isReverseGeocoding = true);
    try {
      final Uri uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1',
      );
      final http.Response response = await http.get(
        uri,
        headers: <String, String>{
          'User-Agent': 'SahayogCooperativeApp/1.0 (contact@sahayog.coop)',
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String displayName = data['display_name'] as String? ?? '';
        final Map<String, dynamic>? address = data['address'] as Map<String, dynamic>?;

        String locality = 'Selected Location';
        if (address != null) {
          locality = (address['suburb'] ??
                  address['neighbourhood'] ??
                  address['residential'] ??
                  address['city_district'] ??
                  address['city'] ??
                  address['town'] ??
                  'Pune Region') as String;
        }

        if (mounted && displayName.isNotEmpty) {
          setState(() {
            _selectedLocality = locality;
            _streetAddressController.text = displayName;
            _isReverseGeocoding = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isReverseGeocoding = false;
        _streetAddressController.text =
            'Near $_selectedLocality (Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)})';
      });
    }
  }

  // =========================================================================
  // 2. LIVE AUTOCOMPLETE SUGGESTIONS
  // =========================================================================
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = <LocationSuggestion>[];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      try {
        final Uri uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
        );
        final http.Response response = await http.get(
          uri,
          headers: <String, String>{
            'User-Agent': 'SahayogCooperativeApp/1.0 (contact@sahayog.coop)',
            'Accept-Language': 'en',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
          final List<LocationSuggestion> results = list.map((dynamic item) {
            final Map<String, dynamic> map = item as Map<String, dynamic>;
            final String name = (map['name'] as String? ?? '').isNotEmpty
                ? map['name'] as String
                : (map['display_name'] as String? ?? '').split(',').first;
            return LocationSuggestion(
              displayName: map['display_name'] as String? ?? '',
              name: name,
              lat: double.tryParse(map['lat'] as String? ?? '') ?? _latitude,
              lon: double.tryParse(map['lon'] as String? ?? '') ?? _longitude,
            );
          }).toList();

          if (mounted) {
            setState(() {
              _suggestions = results;
              _isSearching = false;
            });
            return;
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() => _isSearching = false);
      }
    });
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    setState(() {
      _latitude = suggestion.lat;
      _longitude = suggestion.lon;
      _selectedLocality = suggestion.name;
      _streetAddressController.text = suggestion.displayName;
      _suggestions.clear();
      _searchController.clear();
      _zoom = 16.0;
    });
  }

  // =========================================================================
  // 3. FETCH USER CURRENT LOCATION
  // =========================================================================
  Future<void> _fetchCurrentGpsLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );

        _latitude = position.latitude;
        _longitude = position.longitude;
        _zoom = 16.0;

        // Automatically reverse geocode to street address via OpenStreetMap
        await _reverseGeocode(_latitude, _longitude);

        if (mounted) {
          setState(() {
            _isLoadingGps = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingGps = false);
      // If GPS couldn't be fetched, reverse-geocode current fallback coordinate
      if (_streetAddressController.text.isEmpty) {
        unawaited(_reverseGeocode(_latitude, _longitude));
      }
    }
  }

  // =========================================================================
  // 4. MAP PAN / DRAG LOGIC (1:1 Physical Mercator Drag)
  // =========================================================================
  void _onPanStart(DragStartDetails details) {
    setState(() => _isDraggingMap = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final Offset currentWorld = MercatorProjection.latLngToWorldPixels(_latitude, _longitude, _zoom);
      final Offset newWorld = Offset(
        currentWorld.dx - details.delta.dx,
        currentWorld.dy - details.delta.dy,
      );
      final ({double lat, double lng}) coords = MercatorProjection.worldPixelsToLatLng(newWorld, _zoom);
      _latitude = coords.lat;
      _longitude = coords.lng;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDraggingMap = false);
    // Debounce reverse geocoding after user finishes adjusting the pin
    _dragDebounce?.cancel();
    _dragDebounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(_latitude, _longitude);
    });
  }

  // Build the complete combined address that the worker will see
  String _buildFullAddress() {
    final List<String> parts = <String>[];
    final String flat = _houseFlatController.text.trim();
    final String building = _buildingController.text.trim();
    final String landmark = _landmarkController.text.trim();
    final String street = _streetAddressController.text.trim();

    if (flat.isNotEmpty && building.isNotEmpty) {
      parts.add('$flat, $building');
    } else if (flat.isNotEmpty) {
      parts.add(flat);
    } else if (building.isNotEmpty) {
      parts.add(building);
    }

    if (landmark.isNotEmpty) {
      parts.add('Near $landmark');
    }

    if (street.isNotEmpty) {
      parts.add(street);
    }

    return parts.join(', ');
  }

  void _confirmSelection() {
    final String fullAddr = _buildFullAddress();

    final PickedLocationResult result = PickedLocationResult(
      address: _streetAddressController.text.trim(),
      houseFlatNumber: _houseFlatController.text.trim(),
      buildingName: _buildingController.text.trim(),
      landmark: _landmarkController.text.trim(),
      fullFormattedAddress: fullAddr.isNotEmpty ? fullAddr : _streetAddressController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      locality: _selectedLocality,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: <Widget>[
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Set Exact Service Address',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        _isLoadingGps
                            ? 'Detecting current GPS location...'
                            : (_isReverseGeocoding
                                ? 'Resolving street address...'
                                : '${_latitude.toStringAsFixed(4)}° N, ${_longitude.toStringAsFixed(4)}° E'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: (_isLoadingGps || _isReverseGeocoding) ? AppColors.primary : Colors.grey[600],
                          fontWeight: (_isLoadingGps || _isReverseGeocoding) ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Live Search Bar with Autocomplete Suggestions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search landmark, building, colony, road...',
                prefixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions.clear());
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Autocomplete Dropdown List
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (BuildContext context, int i) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int i) {
                  final LocationSuggestion item = _suggestions[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    subtitle: Text(
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    onTap: () => _selectSuggestion(item),
                  );
                },
              ),
            ),

          const SizedBox(height: 4),

          // Real Live Interactive Map Viewport (OpenStreetMap & CartoDB Raster Tiles)
          SizedBox(
            height: 230,
            width: double.infinity,
            child: Stack(
              children: <Widget>[
                // Real Live Raster Map Layer
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      child: ClipRect(
                        child: LayoutBuilder(
                          builder: (BuildContext ctx, BoxConstraints constraints) {
                            final double width = constraints.maxWidth;
                            final double height = constraints.maxHeight;
                            final int intZoom = _zoom.round();
                            final double tileCount = math.pow(2.0, intZoom).toDouble();

                            final Offset centerWorld =
                                MercatorProjection.latLngToWorldPixels(_latitude, _longitude, _zoom);
                            final double originX = centerWorld.dx - width / 2.0;
                            final double originY = centerWorld.dy - height / 2.0;

                            final int minTx = (originX / 256.0).floor();
                            final int maxTx = ((originX + width) / 256.0).floor();
                            final int minTy = (originY / 256.0).floor();
                            final int maxTy = ((originY + height) / 256.0).floor();

                            final List<Widget> tileWidgets = <Widget>[];

                            for (int tx = minTx; tx <= maxTx; tx++) {
                              for (int ty = minTy; ty <= maxTy; ty++) {
                                if (ty < 0 || ty >= tileCount) continue;
                                final int wrappedTx =
                                    (tx % tileCount.toInt() + tileCount.toInt()) % tileCount.toInt();
                                final double screenLeft = tx * 256.0 - originX;
                                final double screenTop = ty * 256.0 - originY;

                                final String tileUrl = isDark
                                    ? 'https://a.basemaps.cartocdn.com/dark_all/$intZoom/$wrappedTx/$ty.png'
                                    : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/$intZoom/$wrappedTx/$ty.png';

                                tileWidgets.add(
                                  Positioned(
                                    key: ValueKey<String>('tile_${intZoom}_${wrappedTx}_$ty'),
                                    left: screenLeft,
                                    top: screenTop,
                                    width: 256.0,
                                    height: 256.0,
                                    child: Image.network(
                                      tileUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (BuildContext context, Object error,
                                          StackTrace? stackTrace) {
                                        return Image.network(
                                          'https://tile.openstreetmap.org/$intZoom/$wrappedTx/$ty.png',
                                          headers: const <String, String>{
                                            'User-Agent': 'SahayogApp/1.0'
                                          },
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFE2E8F0),
                                            child: const Center(
                                              child: Icon(Icons.map_outlined,
                                                  size: 20, color: Colors.grey),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            }

                            return Stack(
                              children: tileWidgets,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Center Pin (elevates when panning)
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.translationValues(0, _isDraggingMap ? -20 : -10, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (_isReverseGeocoding) ...<Widget>[
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _isDraggingMap
                                    ? 'Release to place pin here'
                                    : (_isReverseGeocoding ? 'Locating...' : _selectedLocality),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.location_pin, size: 42, color: Color(0xFFEF4444)),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: _isDraggingMap ? 6 : 14,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: _isDraggingMap ? 0.2 : 0.45),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Map Guide Hint
                Positioned(
                  top: 10,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.touch_app_outlined, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Drag map to align pin accurately',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Zoom (+ / -) Controls
                Positioned(
                  top: 10,
                  right: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        InkWell(
                          onTap: _zoomIn,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.add, size: 18),
                          ),
                        ),
                        Container(width: 24, height: 1, color: Colors.grey.withValues(alpha: 0.25)),
                        InkWell(
                          onTap: _zoomOut,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.remove, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // OpenStreetMap & CartoDB attribution badge
                Positioned(
                  bottom: 6,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap, © CARTO',
                      style: TextStyle(color: Colors.white, fontSize: 8.5),
                    ),
                  ),
                ),

                // GPS Current Location Button
                Positioned(
                  bottom: 10,
                  right: 14,
                  child: FloatingActionButton.small(
                    heroTag: 'map_gps_btn_doorstep',
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 3,
                    onPressed: _isLoadingGps ? null : _fetchCurrentGpsLocation,
                    child: _isLoadingGps
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Form for Exact Address Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Pinned Street / Colony Resolved from OpenStreetMap
                  TextFormField(
                    controller: _streetAddressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Pinned Area / Street (Auto-resolved from Pin) *',
                      prefixIcon: const Icon(Icons.map_outlined),
                      suffixIcon: _isReverseGeocoding
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Row(
                    children: <Widget>[
                      Icon(Icons.door_front_door_outlined, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Doorstep Details (Shown to worker on arrival)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // House / Flat Number and Floor
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _houseFlatController,
                          decoration: InputDecoration(
                            labelText: 'Flat / House / Floor No *',
                            hintText: 'e.g. Flat 302, 3rd Floor',
                            prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _buildingController,
                          decoration: InputDecoration(
                            labelText: 'Apartment / Society Name *',
                            hintText: 'e.g. Marvel Residency',
                            prefixIcon: const Icon(Icons.apartment_rounded, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Nearby Landmark for Worker
                  TextFormField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      labelText: 'Nearby Landmark / Directions for Worker',
                      hintText: 'e.g. Opposite City Hospital / Near Gate No. 2',
                      prefixIcon: const Icon(Icons.near_me_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _confirmSelection,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'Confirm Location & Exact Address',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
