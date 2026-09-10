import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';

/// Page 12 — Incoming Service Job Alert Modal
/// High-priority dispatch modal with a 30-second countdown timer,
/// customer location, distance, fair wage guaranteed payout, and accept/reject triggers.
class IncomingJobAlertModal extends StatefulWidget {
  const IncomingJobAlertModal({
    super.key,
    this.booking,
    this.onAccept,
    this.onDecline,
  });

  final Booking? booking;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  State<IncomingJobAlertModal> createState() => _IncomingJobAlertModalState();
}

class _IncomingJobAlertModalState extends State<IncomingJobAlertModal>
    with SingleTickerProviderStateMixin {
  int _remainingSeconds = 30;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
        _handleDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleAccept() {
    _timer?.cancel();
    Navigator.of(context).pop();
    widget.onAccept?.call();
  }

  void _handleDecline() {
    _timer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onDecline?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double progress = _remainingSeconds / 30.0;
    final Color timerColor = _remainingSeconds > 15
        ? AppColors.primary
        : _remainingSeconds > 7
            ? Colors.orange
            : AppColors.error;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: <Widget>[
                  // Header Alert Badge with pulsing ring
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (BuildContext ctx, Widget? child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: timerColor.withValues(alpha: 0.12 + (_pulseController.value * 0.1)),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: timerColor.withValues(alpha: 0.25 * _pulseController.value),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 5,
                                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                              ),
                            ),
                            Text(
                              '${_remainingSeconds}s',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: timerColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'INCOMING DISPATCH REQUEST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking?.serviceTitle ?? 'Main Circuit Breaker & Short Circuit Repair',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Fare & Welfare Guarantee Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF27272A), Color(0xFF18181B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'YOUR GUARANTEED PAYOUT',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${widget.booking?.baseFare ?? 450}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                '0% Commission',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                '+₹25 Welfare Credit',
                                style: TextStyle(fontSize: 10, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer & Location Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Customer
                        Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    widget.booking?.customerName ?? 'Aditya Shah',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                                  ),
                                  const SizedBox(height: 1),
                                  const Row(
                                    children: <Widget>[
                                      Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      SizedBox(width: 3),
                                      Text('4.9 Rating • 12 Verified Coop Requests', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22),

                        // Distance & Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    '1.4 km away (Approx. 6 mins travel time)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.booking?.serviceAddress ?? 'Flat 402, Marvel Residency, Paud Road, Kothrud, Pune - 411038',
                                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22),

                        // Requirement Notes
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(Icons.description_outlined, color: Colors.grey, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Client Requirement Notes',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.booking?.serviceDescription.isNotEmpty == true
                                        ? widget.booking!.serviceDescription
                                        : 'Sparking observed in main distribution board when running AC. Immediate inspection needed.',
                                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Accept / Decline Action Bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _handleDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _handleAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'Accept Job',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
