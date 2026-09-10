import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../controllers/worker_controller.dart';
import '../../../common/presentation/widgets/empty_state.dart';

class WorkerEarningsTab extends ConsumerWidget {
  const WorkerEarningsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorkerDashboardState dashState = ref.watch(workerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Booking> completedBookings = dashState.historicalBookings
        .where((Booking b) => b.status == BookingStatus.completed || b.status == BookingStatus.paymentConfirmed || b.status == BookingStatus.reviewed)
        .toList()
      ..sort((Booking a, Booking b) => (b.updatedAt ?? b.createdAt ?? DateTime.now()).compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now())); // Newest first

    int totalEarnings = 0;
    int totalWelfareContribution = 0;

    for (final Booking b in completedBookings) {
      totalEarnings += b.baseFare;
      totalWelfareContribution += b.welfareFee;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(workerDashboardProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Main Earnings Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Total Lifetime Earnings',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹$totalEarnings',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Welfare Pool Contribution
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: <Widget>[
                    const CircleAvatar(
                      backgroundColor: AppColors.success,
                      child: Icon(Icons.volunteer_activism, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Cooperative Welfare Contribution',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                          Text(
                            'You have contributed ₹$totalWelfareContribution to the cooperative fund.',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Transaction History
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (completedBookings.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No earnings yet',
                  subtitle: 'Complete jobs to see your earnings here.',
                )
              else
                ...completedBookings.map((Booking b) => _buildTransactionItem(b, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Booking booking, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_downward, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  booking.serviceTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(booking.updatedAt ?? booking.createdAt ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+₹${booking.baseFare}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
