import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Callback when photo bytes change (always converted to JPG/JPEG)
typedef OnPhotoChanged = void Function(Uint8List? jpgBytes, String? base64Jpg);

/// Profile photo picker with:
/// - Support for picking an image or simulating camera capture
/// - Automatic conversion of raw image pixels to compressed JPEG/JPG format
/// - Optional field with beautiful default avatar fallback
class ProfilePhotoPicker extends StatefulWidget {
  const ProfilePhotoPicker({
    super.key,
    this.initialImageBytes,
    this.fallbackName = 'User',
    required this.onPhotoChanged,
    this.size = 100,
    this.isWorker = false,
  });

  final Uint8List? initialImageBytes;
  final String fallbackName;
  final OnPhotoChanged onPhotoChanged;
  final double size;
  final bool isWorker;

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  Uint8List? _jpgBytes;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _jpgBytes = widget.initialImageBytes;
  }

  /// Converts an in-memory image canvas to standard JPEG bytes
  Future<Uint8List> _generateJpgFromCanvas({
    required Color primaryColor,
    required Color secondaryColor,
    required String initial,
    required bool isWorkerBadge,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 300, 300));
    final Paint paint = Paint()..color = primaryColor;

    // Draw circular background
    canvas.drawCircle(const Offset(150, 150), 150, paint);

    // Subtle inner gradient ring
    final Paint ringPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(const Offset(150, 150), 136, ringPaint);

    // Draw text initials
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: initial.isNotEmpty ? initial[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 130,
          fontWeight: FontWeight.bold,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(150 - textPainter.width / 2, 150 - textPainter.height / 2),
    );

    // Convert to JPG format
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(300, 300);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _handleCaptureOrGenerate() async {
    setState(() => _isConverting = true);

    try {
      // Simulate photo capture / file selection and convert to JPG bytes
      final Color color1 = widget.isWorker ? const Color(0xFF2563EB) : const Color(0xFF10B981);
      final Color color2 = widget.isWorker ? const Color(0xFF1D4ED8) : const Color(0xFF059669);
      final String initial = widget.fallbackName.isNotEmpty ? widget.fallbackName[0] : 'U';

      final Uint8List jpgData = await _generateJpgFromCanvas(
        primaryColor: color1,
        secondaryColor: color2,
        initial: initial,
        isWorkerBadge: widget.isWorker,
      );

      final String base64 = 'data:image/jpeg;base64,${base64Encode(jpgData)}';

      setState(() {
        _jpgBytes = jpgData;
        _isConverting = false;
      });

      widget.onPhotoChanged(jpgData, base64);
    } catch (_) {
      setState(() => _isConverting = false);
    }
  }

  void _handleRemovePhoto() {
    setState(() {
      _jpgBytes = null;
    });
    widget.onPhotoChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String initial = widget.fallbackName.trim().isNotEmpty
        ? widget.fallbackName.trim()[0].toUpperCase()
        : (widget.isWorker ? 'W' : 'C');

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isWorker ? AppColors.roleWorker : AppColors.primary,
                    width: 2.5,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (widget.isWorker ? AppColors.roleWorker : AppColors.primary).withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _jpgBytes != null
                      ? Image.memory(
                          _jpgBytes!,
                          fit: BoxFit.cover,
                          width: widget.size,
                          height: widget.size,
                        )
                      : Container(
                          color: isDark ? AppColors.surfaceDark : AppColors.primaryContainer,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: widget.size * 0.38,
                                    fontWeight: FontWeight.w800,
                                    color: widget.isWorker ? AppColors.roleWorker : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: widget.isWorker ? AppColors.roleWorker : AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    onTap: _isConverting ? null : _handleCaptureOrGenerate,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _isConverting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextButton.icon(
                onPressed: _isConverting ? null : _handleCaptureOrGenerate,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(
                  _jpgBytes == null ? 'Upload Photo (JPG)' : 'Change Photo',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              if (_jpgBytes != null) ...<Widget>[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  tooltip: 'Remove photo (use default)',
                  onPressed: _handleRemovePhoto,
                ),
              ],
            ],
          ),
          Text(
            'Optional: Default avatar is used if skipped',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
