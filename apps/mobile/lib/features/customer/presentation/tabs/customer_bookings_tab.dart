import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../controllers/customer_booking_controller.dart';
import '../booking_timeline_screen.dart';

class CustomerBookingsTab extends ConsumerStatefulWidget {
  const CustomerBookingsTab({super.key});

  @override
  ConsumerState<CustomerBookingsTab> createState() => _CustomerBookingsTabState();
}

class _CustomerBookingsTabState extends ConsumerState<CustomerBookingsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CustomerDashboardState dashState = ref.watch(customerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Booking> active = dashState.bookings
        .where((Booking b) => b.status == BookingStatus.inProgress || b.status == BookingStatus.arrived)
        .toList();
    final List<Booking> upcoming = dashState.bookings
        .where((Booking b) => b.status == BookingStatus.requested || b.status == BookingStatus.accepted || b.status == BookingStatus.scheduled)
        .toList();
    final List<Booking> completed = dashState.bookings
        .where((Booking b) => b.status == BookingStatus.completed || b.status == BookingStatus.paymentConfirmed || b.status == BookingStatus.reviewed)
        .toList();
    final List<Booking> cancelled = dashState.bookings
        .where((Booking b) => b.status == BookingStatus.cancelled || b.status == BookingStatus.rejected || b.status == BookingStatus.expired)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Completed (${completed.length})'),
            Tab(text: 'Cancelled (${cancelled.length})'),
          ],
        ),
      ),
      body: dashState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(customerDashboardProvider.notifier).loadCustomerBookings(),
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildBookingsList(active, isDark),
                  _buildBookingsList(upcoming, isDark),
                  _buildBookingsList(completed, isDark),
                  _buildBookingsList(cancelled, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, bool isDark) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your bookings will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildBookingCard(context, bookings[index], isDark);
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, bool isDark) {
    final Color statusColor = _statusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => BookingTimelineScreen(booking: booking),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    booking.trackingCode,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.displayName.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booking.serviceTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(Icons.calendar_today, size: 14, color: isDark ? AppColors.textSecondaryDark : Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat.yMMMd().format(booking.scheduledDate)} • ${booking.timeSlot}',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (booking.workerName != null)
                Row(
                  children: <Widget>[
                    Icon(Icons.person, size: 14, color: isDark ? AppColors.textSecondaryDark : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      booking.workerName!,
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '₹${booking.totalAmount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BookingStatus status) {
    return switch (status) {
      BookingStatus.requested => AppColors.warning,
      BookingStatus.accepted || BookingStatus.scheduled => AppColors.info,
      BookingStatus.arrived => AppColors.primary,
      BookingStatus.inProgress => AppColors.primary,
      BookingStatus.completed => AppColors.success,
      BookingStatus.paymentConfirmed => AppColors.success,
      BookingStatus.reviewed => AppColors.success,
      BookingStatus.rejected => AppColors.error,
      BookingStatus.cancelled => AppColors.error,
      BookingStatus.expired => Colors.grey,
    };
  }
}
