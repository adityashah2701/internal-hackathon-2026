import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';

/// Page 8 — Live Worker Matching / Radar Modal Sheet
/// Features an animated radar pulse, cooperative node discovery,
/// nearby verified worker cards, and direct instant booking.
class WorkerMatchingRadarModal extends StatefulWidget {
  const WorkerMatchingRadarModal({
    super.key,
    required this.booking,
    this.onWorkerSelected,
  });

  final Booking booking;
  final ValueChanged<String>? onWorkerSelected;

  @override
  State<WorkerMatchingRadarModal> createState() => _WorkerMatchingRadarModalState();
}

class _WorkerMatchingRadarModalState extends State<WorkerMatchingRadarModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  int _searchStage = 0; // 0: broadcasting, 1: matching, 2: workers discovered, 3: worker confirmed
  Timer? _stageTimer;
  String? _selectedWorkerName;

  final List<_NearbyWorkerCandidate> _candidates = const <_NearbyWorkerCandidate>[
    _NearbyWorkerCandidate(
      id: 'w-101',
      name: 'Ramesh Sharma',
      badge: 'Level 4 Master Artisan',
      coopChapter: 'Pune West Cooperative #4182',
      rating: 4.9,
      totalJobs: 148,
      distanceKm: 1.2,
      etaMins: 12,
      hourlyRate: 350,
      avatarUrl: 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?w=150',
      isTopRated: true,
    ),
    _NearbyWorkerCandidate(
      id: 'w-102',
      name: 'Vijay Patil',
      badge: 'Certified Wireman',
      coopChapter: 'Kothrud Trade Union #1093',
      rating: 4.85,
      totalJobs: 92,
      distanceKm: 2.1,
      etaMins: 18,
      hourlyRate: 350,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      isTopRated: false,
    ),
    _NearbyWorkerCandidate(
      id: 'w-103',
      name: 'Santosh Shinde',
      badge: 'Senior Technician',
      coopChapter: 'Deccan Artisan Guild #5512',
      rating: 4.78,
      totalJobs: 67,
      distanceKm: 3.4,
      etaMins: 25,
      hourlyRate: 350,
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      isTopRated: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _stageTimer = Timer.periodic(const Duration(milliseconds: 1600), (Timer t) {
      if (!mounted) return;
      if (_searchStage < 2) {
        setState(() => _searchStage++);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _stageTimer?.cancel();
    super.dispose();
  }

  void _confirmWorkerSelection(_NearbyWorkerCandidate candidate) {
    setState(() {
      _selectedWorkerName = candidate.name;
      _searchStage = 3;
    });
    widget.onWorkerSelected?.call(candidate.id);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          // Sheet Drag Handle & Close
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SizedBox(width: 40),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: <Widget>[
                  if (_searchStage < 3) ...<Widget>[
                    // Radar Animation Box
                    SizedBox(
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          AnimatedBuilder(
                            animation: _radarController,
                            builder: (BuildContext ctx, Widget? child) {
                              return CustomPaint(
                                size: const Size(190, 190),
                                painter: _RadarSweepPainter(
                                  animationValue: _radarController.value,
                                  isDark: isDark,
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_searching_rounded,
                              color: AppColors.onPrimary,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stage Status Description
                    Text(
                      _searchStage == 0
                          ? 'Broadcasting Request to Cooperative Node...'
                          : _searchStage == 1
                              ? 'Scanning Verified Artisans within 5.0 km...'
                              : '3 Certified Artisans Ready for Dispatch',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Request #${widget.booking.trackingCode} • ${widget.booking.serviceTitle}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 20),
                  ] else ...<Widget>[
                    // Confirmed Worker Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 10, bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Worker Dispatched & Confirmed!',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_selectedWorkerName has accepted and is preparing their toolkit.',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Candidate List / Confirmed Details
                  if (_searchStage >= 2 && _searchStage < 3) ...<Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Available Verified Members',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Direct Union Dispatch',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._candidates.map((_NearbyWorkerCandidate candidate) {
                      return _buildWorkerCard(context, candidate, isDark);
                    }),
                  ] else if (_searchStage == 3) ...<Widget>[
                    _buildDispatchConfirmationCard(isDark),
                  ] else ...<Widget>[
                    // Radar Scanning Placeholder Animation Cards
                    const SizedBox(height: 30),
                    Center(
                      child: Column(
                        children: <Widget>[
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Matching with union-certified craftspersons...\nZero algorithmic surge pricing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _searchStage == 3
                  ? SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('View in Bookings Tab'),
                      ),
                    )
                  : _searchStage >= 2
                      ? SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmWorkerSelection(_candidates.first),
                            icon: const Icon(Icons.bolt_rounded, color: AppColors.primary),
                            label: const Text('Auto-Assign Nearest (Ramesh Sharma)'),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context, _NearbyWorkerCandidate c, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: c.isTopRated
              ? AppColors.primary.withValues(alpha: 0.6)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: c.isTopRated ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    c.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.badge,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        c.coopChapter,
                        style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            c.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.totalJobs} jobs',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.near_me_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${c.distanceKm} km away (${c.etaMins} mins)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: () => _confirmWorkerSelection(c),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Book Directly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchConfirmationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'SECURITY START OTP',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey),
              ),
              Text(
                'Keep this confidential',
                style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                widget.booking.startOtp,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Share this 4-digit code with the worker only when they arrive at your location to commence authorized work.',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.35),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Assigned Craftsman', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(_selectedWorkerName ?? 'Ramesh Sharma', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Scheduled Slot', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(widget.booking.timeSlot, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Total Payable', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('₹${widget.booking.totalAmount}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NearbyWorkerCandidate {
  const _NearbyWorkerCandidate({
    required this.id,
    required this.name,
    required this.badge,
    required this.coopChapter,
    required this.rating,
    required this.totalJobs,
    required this.distanceKm,
    required this.etaMins,
    required this.hourlyRate,
    required this.avatarUrl,
    required this.isTopRated,
  });

  final String id;
  final String name;
  final String badge;
  final String coopChapter;
  final double rating;
  final int totalJobs;
  final double distanceKm;
  final int etaMins;
  final int hourlyRate;
  final String avatarUrl;
  final bool isTopRated;
}

/// Custom painter for the animated radar sweep and ripple rings
class _RadarSweepPainter extends CustomPainter {
  _RadarSweepPainter({
    required this.animationValue,
    required this.isDark,
  });

  final double animationValue;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    final Paint ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Concentric grid rings
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3), ringPaint);
    }

    // Crosshair axes
    final Paint axisPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    // Expanding ripple waves
    for (int i = 0; i < 2; i++) {
      final double waveProgress = (animationValue + (i * 0.5)) % 1.0;
      final double waveRadius = maxRadius * waveProgress;
      final double waveOpacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.4;

      final Paint wavePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: waveOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }

    // Sweeping radar beam gradient
    final double angle = animationValue * 2 * math.pi;
    final Paint sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: <Color>[
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primary.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: maxRadius),
      0,
      math.pi / 2,
      true,
      sweepPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
