import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/errors/app_exception.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const NetworkException(message: 'Location services are disabled. Please enable them in settings.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const NetworkException(message: 'Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const NetworkException(message: 'Location permissions are permanently denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      )
    );
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // TODO: Fix geocoding API call
    return 'Mock Address, City';
  }
}

final Provider<LocationService> locationServiceProvider = Provider<LocationService>((Ref ref) => LocationService());
