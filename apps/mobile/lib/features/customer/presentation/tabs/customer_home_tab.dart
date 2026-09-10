import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/service_category.dart';
import '../../../../data/models/user_profile.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/customer_booking_controller.dart';

class CustomerHomeTab extends ConsumerWidget {
  const CustomerHomeTab({super.key});

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
    final CustomerDashboardState dashState = ref.watch(customerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String userName = switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile.fullName.split(' ').first,
      _ => '',
    };

    final List<Booking> activeBookings = dashState.bookings
        .where((Booking b) => b.status.isActive || b.status == BookingStatus.arrived)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(customerDashboardProvider.notifier).loadCustomerBookings();
            await ref.read(customerDashboardProvider.notifier).loadServiceCatalog();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${_greeting()}, $userName',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What service do you need today?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                // Search Bar
                GestureDetector(
                  onTap: () => context.go('/customer/services'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        const SizedBox(width: 12),
                        Text(
                          'Search for services (e.g., Electrician)',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Popular Services',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.go('/customer/services'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildServiceGrid(context, dashState, isDark),
                const SizedBox(height: 32),
                Text(
                  'Your Active Booking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (dashState.isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ))
                else if (activeBookings.isEmpty)
                  _buildEmptyBookingState(isDark)
                else
                  ...activeBookings.take(2).map((Booking b) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildActiveBookingCard(context, b, isDark),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context, CustomerDashboardState dashState, bool isDark) {
    if (dashState.isCatalogLoading) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (dashState.categories.isEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            'No services available yet',
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dashState.categories.length,
        itemBuilder: (BuildContext context, int index) {
          final ServiceCategory cat = dashState.categories[index];
          return _buildServiceCard(context, cat, isDark);
        },
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceCategory category, bool isDark) {
    final IconData icon = _mapIconName(category.iconName);

    return GestureDetector(
      onTap: () => context.go('/customer/services'),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBookingState(bool isDark) {
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
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No active bookings',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your upcoming services will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingCard(BuildContext context, Booking booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status.displayName,
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? AppColors.borderDark : AppColors.primaryContainer,
                child: const Icon(Icons.person, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.workerName ?? 'Finding worker...',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              Text(
                '₹${booking.totalAmount}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/customer/bookings'),
              child: const Text('View Booking'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _mapIconName(String iconName) {
    return switch (iconName) {
      'electrical_services' => Icons.electrical_services,
      'plumbing' => Icons.plumbing,
      'handyman' => Icons.handyman,
      'ac_unit' => Icons.ac_unit,
      'format_paint' || 'format_paint_rounded' => Icons.format_paint,
      'carpenter' => Icons.carpenter,
      'cleaning_services' => Icons.cleaning_services,
      'home_repair_service' => Icons.home_repair_service,
      'build' || 'build_rounded' => Icons.build_rounded,
      _ => Icons.build_rounded,
    };
  }
}
