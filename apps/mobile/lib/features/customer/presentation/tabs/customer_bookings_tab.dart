import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../../common/presentation/widgets/chat_call_modal.dart';
import '../../../common/presentation/widgets/invoice_modal.dart';
import '../../../common/presentation/widgets/safety_sos_modal.dart';
import '../../controllers/customer_booking_controller.dart';
import '../payment_screen.dart';

class CustomerBookingsTab extends ConsumerStatefulWidget {
  const CustomerBookingsTab({super.key});

  @override
  ConsumerState<CustomerBookingsTab> createState() => _CustomerBookingsTabState();
}

class _CustomerBookingsTabState extends ConsumerState<CustomerBookingsTab> {
  String _selectedFilter = 'All';

  final List<String> _filters = <String>['All', 'Active', 'Completed', 'Cancelled'];

  (Color, String) _statusBadge(BookingStatus status) {
    return switch (status) {
      BookingStatus.requested => (AppColors.warning, 'Requested'),
      BookingStatus.accepted => (AppColors.primary, 'Worker Accepted'),
      BookingStatus.scheduled => (AppColors.primary, 'Scheduled'),
      BookingStatus.arrived => (AppColors.primary, 'Craftsman Arrived'),
      BookingStatus.inProgress => (AppColors.primary, 'In Progress'),
      BookingStatus.completed => (AppColors.success, 'Completed'),
      BookingStatus.paymentConfirmed => (AppColors.success, 'Paid & Verified'),
      BookingStatus.reviewed => (AppColors.success, 'Reviewed'),
      BookingStatus.cancelled => (AppColors.error, 'Cancelled'),
      BookingStatus.rejected => (AppColors.error, 'Declined'),
      BookingStatus.expired => (Colors.grey, 'Expired'),
    };
  }

  void _openReviewModal(BuildContext context, Booking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => _CustomerReviewSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomerDashboardState state = ref.watch(customerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Booking> filteredList = state.bookings.where((Booking b) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Active') return b.status.isActive;
      if (_selectedFilter == 'Completed') {
        return b.status == BookingStatus.completed ||
            b.status == BookingStatus.paymentConfirmed ||
            b.status == BookingStatus.reviewed;
      }
      if (_selectedFilter == 'Cancelled') {
        return b.status == BookingStatus.cancelled || b.status == BookingStatus.rejected;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(customerDashboardProvider.notifier).loadCustomerBookings();
        },
        child: Column(
          children: <Widget>[
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((String f) {
                    final bool isSelected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.onPrimary
                              : (isDark ? Colors.white70 : const Color(0xFF374151)),
                        ),
                        onSelected: (bool sel) {
                          if (sel) setState(() => _selectedFilter = f);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1),

            // Bookings List
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings found in this view.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Browse services to post a new cooperative request.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Booking booking = filteredList[index];
                        return _buildBookingCard(context, booking, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, bool isDark) {
    final (Color statusColor, String statusLabel) = _statusBadge(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header: Category, Tracking Code & Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      booking.serviceTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${booking.trackingCode}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Time & Location Info
            Row(
              children: <Widget>[
                Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${booking.scheduledDate} • ${booking.timeSlot}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(Icons.location_on_rounded, size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.serviceAddress,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Worker Assigned Row
            if (booking.workerName != null) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.engineering_rounded, size: 16, color: AppColors.roleWorker),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Craftsman: ${booking.workerName}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Text('Cooperative Certified', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            // OTP Verification Banner (When arrived or in progress)
            if (booking.status == BookingStatus.arrived || booking.status == BookingStatus.inProgress) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.pin_rounded, color: Color(0xFF78350F), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Job Start OTP (Share with craftsman on arrival)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.trackingCode.length >= 4
                                ? booking.trackingCode.substring(booking.trackingCode.length - 4)
                                : '4821',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF78350F),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Price & Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Total Fare', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                    Text(
                      '₹${booking.totalAmount}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ],
                ),

                // Contextual Action Buttons
                Row(
                  children: <Widget>[
                    // Chat & Call for active bookings
                    if (booking.status == BookingStatus.accepted ||
                        booking.status == BookingStatus.scheduled ||
                        booking.status == BookingStatus.arrived ||
                        booking.status == BookingStatus.inProgress) ...<Widget>[
                      IconButton(
                        tooltip: 'Chat & Call',
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext ctx) => ChatCallModal(
                              peerName: booking.workerName ?? 'Assigned Artisan',
                              peerRole: 'Cooperative Artisan',
                              trackingCode: booking.trackingCode,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Safety & SOS',
                        icon: const Icon(Icons.shield_outlined, color: AppColors.error, size: 20),
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext ctx) => const SafetySosModal(),
                          );
                        },
                      ),
                    ],

                    // Invoice action for completed / reviewed
                    if (booking.status == BookingStatus.completed ||
                        booking.status == BookingStatus.paymentConfirmed ||
                        booking.status == BookingStatus.reviewed)
                      IconButton(
                        tooltip: 'View Invoice',
                        icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                        onPressed: () => InvoiceModal.show(context, booking),
                      ),

                    // Pay Now
                    if (booking.status == BookingStatus.completed)
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (BuildContext ctx) => PaymentScreen(booking: booking),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Pay Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),

                    // Review Worker
                    if (booking.status == BookingStatus.paymentConfirmed)
                      FilledButton.tonal(
                        onPressed: () => _openReviewModal(context, booking),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Rate Worker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),

                    // Cancel Booking
                    if (booking.status == BookingStatus.requested || booking.status == BookingStatus.accepted)
                      OutlinedButton(
                        onPressed: () => _confirmCancelBooking(context, booking),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelBooking(BuildContext context, Booking booking) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Cancel Booking?'),
          content: Text('Are you sure you want to cancel request ${booking.trackingCode}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Keep Booking'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(customerDashboardProvider.notifier).cancelBooking(booking.id);
              },
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerReviewSheet extends ConsumerStatefulWidget {
  const _CustomerReviewSheet({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_CustomerReviewSheet> createState() => _CustomerReviewSheetState();
}

class _CustomerReviewSheetState extends ConsumerState<_CustomerReviewSheet> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Rate ${widget.booking.workerName ?? 'Craftsman'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Your feedback helps maintain state cooperative quality standards.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(5, (int i) {
              return IconButton(
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 36,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Feedback Input
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share remarks on timeliness, craftsmanship, and professionalism...',
            ),
          ),
          const SizedBox(height: 20),

          // Submit
          FilledButton(
            onPressed: () {
              ref.read(customerDashboardProvider.notifier).submitReview(
                    bookingId: widget.booking.id,
                    workerId: widget.booking.workerId ?? '',
                    rating: _rating,
                    comment: _feedbackController.text.trim(),
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Submit Cooperative Review'),
          ),
        ],
      ),
    );
  }
}
