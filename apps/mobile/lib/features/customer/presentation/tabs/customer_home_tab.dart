import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/service_category.dart';
import '../../../../data/models/user_profile.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/customer_booking_controller.dart';
import '../../utils/service_image_helper.dart';

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
        height: 156,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (dashState.categories.isEmpty) {
      return SizedBox(
        height: 156,
        child: Center(
          child: Text(
            'No services available yet',
            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    return SizedBox(
      height: 156,
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
    final String imageUrl = ServiceImageHelper.getCategoryImageUrl(category.name);

    return InkWell(
      onTap: () => context.go('/customer/services'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Actual photograph of the service
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext ctx, Widget child, ImageChunkEvent? progress) {
                        if (progress == null) return child;
                        return Container(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (BuildContext ctx, Object err, StackTrace? stack) {
                        return Container(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          child: const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 28),
                        );
                      },
                    ),
                    // Gradient shadow overlay at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.transparent,
                              (isDark ? AppColors.surfaceDark : Colors.white).withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Service Title & Starting Price
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.basePrice > 0 ? 'from ₹${category.basePrice}' : 'Available Now',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}
