import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../controllers/worker_controller.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(BookingStatus newStatus, {String? otp}) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // TODO: If OTP is required, validate it against the backend here.
      // For MVP simulation, we just update the status if they entered '1234'.
      if (otp != null && otp != '1234') {
        throw Exception('Invalid OTP. Please ask the customer for the correct code.');
      }

      await ref.read(workerDashboardProvider.notifier).updateBookingStatus(
        widget.bookingId,
        newStatus,
      );

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkerDashboardState state = ref.watch(workerDashboardProvider);
    final Booking? booking = state.activeBookings.where((Booking b) => b.id == widget.bookingId).firstOrNull;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Job')),
        body: const Center(child: Text('Job not found.')),
      );
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Job', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Job Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    booking.serviceTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(booking.customerName ?? 'Customer'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.serviceAddress,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('Estimated Earnings:'),
                      Text(
                        '₹${booking.totalAmount}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Status Timeline & Actions
            _buildStatusCard(booking, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Booking booking, bool isDark) {
    if (booking.status == BookingStatus.accepted || booking.status == BookingStatus.scheduled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Next Step: Arrive at Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _updateStatus(BookingStatus.arrived),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2))
                : const Text('Mark as Arrived', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }

    if (booking.status == BookingStatus.arrived) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'OTP Verification Required',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warning),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask the customer for the 4-digit PIN displayed on their app to start the job.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: 'Enter Customer OTP',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () {
                    if (_otpController.text.length != 4) {
                      setState(() => _errorMessage = 'Please enter a 4-digit OTP');
                      return;
                    }
                    _updateStatus(BookingStatus.inProgress, otp: _otpController.text);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2))
                : const Text('Verify & Start Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }

    if (booking.status == BookingStatus.inProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Job in Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : () => _updateStatus(BookingStatus.completed),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Mark Job Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }

    if (booking.status == BookingStatus.completed) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(Icons.check_circle, color: AppColors.success, size: 64),
          SizedBox(height: 16),
          Text(
            'Job Completed',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Waiting for customer payment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
