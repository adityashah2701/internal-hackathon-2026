import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../controllers/worker_controller.dart';
import '../active_job_screen.dart';

class WorkerHomeTab extends ConsumerWidget {
  const WorkerHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorkerDashboardState dashState = ref.watch(workerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (dashState.isLoading && dashState.profile.id.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Booking? activeJob = dashState.activeBookings.isNotEmpty ? dashState.activeBookings.first : null;
    final List<Booking> availableRequests = dashState.availableBookings;

    // Calculate today's earnings (completed today)
    final DateTime today = DateTime.now();
    int todayEarnings = 0;
    for (final Booking b in dashState.historicalBookings) {
      final DateTime date = b.updatedAt ?? b.createdAt ?? DateTime.now();
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        if (b.status == BookingStatus.completed || b.status == BookingStatus.paymentConfirmed || b.status == BookingStatus.reviewed) {
          // Worker gets baseFare (subtotal), cooperative gets welfareFee
          todayEarnings += b.baseFare;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayog Workspace', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: <Widget>[
          Switch(
            value: dashState.profile.isAvailable,
            onChanged: (bool val) => ref.read(workerDashboardProvider.notifier).toggleAvailability(val),
            activeColor: AppColors.success,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(workerDashboardProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dashState.profile.isAvailable ? AppColors.success : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dashState.profile.isAvailable ? 'Online and accepting jobs' : 'Offline',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildSummaryCard(
                      'Today\'s Earnings',
                      '₹$todayEarnings',
                      Icons.account_balance_wallet,
                      AppColors.success,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Completed',
                      '${dashState.historicalBookings.length} Jobs',
                      Icons.check_circle,
                      AppColors.primary,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (dashState.profile.isAvailable && availableRequests.isNotEmpty) ...<Widget>[
                Text(
                  'New Job Requests (${availableRequests.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...availableRequests.map((Booking b) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildJobRequestCard(context, ref, b, isDark),
                    )),
                const SizedBox(height: 16),
              ],
              const Text('Active Job', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (activeJob == null)
                _buildEmptyState(
                  isDark,
                  dashState.profile.isAvailable
                      ? 'No active jobs at the moment. Stay online to receive requests.'
                      : 'You are currently offline. Toggle your status to receive jobs.',
                )
              else
                _buildActiveJobCard(context, ref, activeJob, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color iconColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: iconColor),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildJobRequestCard(BuildContext context, WidgetRef ref, Booking booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  booking.serviceTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (booking.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('URGENT', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                Text('₹${booking.baseFare}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.serviceAddress,
                  style: const TextStyle(color: AppColors.primaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.access_time, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                booking.timeSlot,
                style: const TextStyle(color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(workerDashboardProvider.notifier).rejectBooking(booking.id),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => ref.read(workerDashboardProvider.notifier).acceptBooking(booking.id),
                  child: const Text('Accept'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(BuildContext context, WidgetRef ref, Booking booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                booking.serviceTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status.displayName.toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.serviceAddress,
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => ActiveJobScreen(bookingId: booking.id),
                  ),
                );
              },
              child: const Text('View Job Details'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.work_off, size: 48, color: isDark ? AppColors.textSecondaryDark : Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : Colors.grey),
          ),
        ],
      ),
    );
  }
}
