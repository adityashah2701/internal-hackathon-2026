import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../controllers/customer_booking_controller.dart';

/// Booking Timeline Screen — shows the full status progression for a booking.
/// Navigated to from the Customer Bookings Tab when a booking card is tapped.
class BookingTimelineScreen extends ConsumerStatefulWidget {
  const BookingTimelineScreen({
    super.key,
    required this.booking,
  });

  final Booking booking;

  @override
  ConsumerState<BookingTimelineScreen> createState() => _BookingTimelineScreenState();
}

class _BookingTimelineScreenState extends ConsumerState<BookingTimelineScreen> {
  late Razorpay _razorpay;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isPaying = true);
    try {
      await ref.read(customerDashboardProvider.notifier).updateBookingStatus(
        widget.booking.id,
        BookingStatus.paymentConfirmed,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful!')),
        );
        Navigator.of(context).pop(); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _openCheckout() {
    final Map<String, Object> options = <String, Object>{
      'key': 'rzp_test_rYQpXwQY', // Standard test key (dummy fallback)
      'amount': widget.booking.totalAmount * 100, // in paise
      'name': 'Jelp Cooperative',
      'description': 'Payment for ${widget.booking.serviceTitle}',
      'prefill': <String, String>{
        'contact': widget.booking.customerName ?? '',
        'email': 'customer@jelp.local'
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Booking booking = widget.booking;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Booking ID Header
            Text(
              'Booking #${booking.trackingCode}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              booking.serviceTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${booking.workerName ?? 'Pending Worker'} • ${booking.serviceCategory}',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (booking.startCode != null && booking.status.isActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      'Share this Secret Code with Worker',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking.startCode!,
                      style: const TextStyle(
                        fontSize: 32,
                        letterSpacing: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 32),

            // Timeline
            const Text(
              'Booking Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _buildTimelineStep(
              title: 'Request Sent',
              subtitle: 'Status: Requested',
              isComplete: booking.status != BookingStatus.requested,
              isFirst: true,
              isDark: isDark,
              isCurrent: booking.status == BookingStatus.requested,
            ),
            _buildTimelineStep(
              title: 'Worker Accepted',
              subtitle: 'Status: Accepted',
              isComplete: booking.status.index > BookingStatus.accepted.index,
              isDark: isDark,
              isCurrent: booking.status == BookingStatus.accepted,
            ),
            _buildTimelineStep(
              title: 'Worker Scheduled',
              subtitle: 'Status: Scheduled',
              isComplete: booking.status.index > BookingStatus.scheduled.index,
              isDark: isDark,
              isCurrent: booking.status == BookingStatus.scheduled,
            ),
            _buildTimelineStep(
              title: 'Worker On The Way',
              subtitle: 'Status: Arrived',
              isComplete: booking.status.index > BookingStatus.arrived.index,
              isDark: isDark,
              isCurrent: booking.status == BookingStatus.arrived,
            ),
            _buildTimelineStep(
              title: 'Job Started',
              subtitle: 'Status: In Progress',
              isComplete: booking.status.index > BookingStatus.inProgress.index,
              isDark: isDark,
              isCurrent: booking.status == BookingStatus.inProgress,
            ),
            _buildTimelineStep(
              title: 'Job Completed',
              subtitle: 'Status: Completed',
              isComplete: booking.status.index > BookingStatus.completed.index,
              isDark: isDark,
              isCurrent: booking.status == BookingStatus.completed,
            ),
            _buildTimelineStep(
              title: 'Payment',
              subtitle: 'Status: Payment Confirmed',
              isComplete: booking.status.index > BookingStatus.paymentConfirmed.index,
              isDark: isDark,
              isCurrent: booking.status == BookingStatus.paymentConfirmed,
            ),
            _buildTimelineStep(
              title: 'Review',
              subtitle: 'Status: Reviewed',
              isComplete: booking.status == BookingStatus.reviewed,
              isLast: true,
              isDark: isDark,
              isCurrent: booking.status == BookingStatus.reviewed,
            ),

            const SizedBox(height: 32),

            // Booking Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.handyman, 'Service', booking.serviceTitle, isDark),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.person, 'Worker', booking.workerName ?? 'Pending', isDark),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.calendar_today, 'Scheduled', booking.scheduledDate.toString().split(' ')[0], isDark),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.location_on, 'Location', booking.serviceAddress, isDark),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Estimated Total',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '₹${booking.totalAmount}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contextual Actions
            if (booking.status == BookingStatus.completed)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isPaying ? null : _openCheckout,
                  icon: _isPaying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.payment),
                  label: Text(_isPaying ? 'Processing...' : 'Pay with Razorpay', style: const TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else if (booking.status.isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone),
                  label: const Text('Contact Worker'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isComplete,
    required bool isDark,
    bool isCurrent = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final Color dotColor = isComplete
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);
    final Color lineColor = isComplete
        ? AppColors.success
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Timeline line and dot
          SizedBox(
            width: 32,
            child: Column(
              children: <Widget>[
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 8,
                    color: lineColor,
                  ),
                Container(
                  width: isCurrent ? 16 : 12,
                  height: isCurrent ? 16 : 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: AppColors.primary, width: 3)
                        : null,
                    boxShadow: isCurrent
                        ? <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isComplete
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 24),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      fontSize: isCurrent ? 15 : 14,
                      color: isComplete || isCurrent
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
