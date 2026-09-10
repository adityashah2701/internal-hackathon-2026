import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/user_profile.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/customer_booking_controller.dart';

class CustomerProfileTab extends ConsumerWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
    final CustomerDashboardState dashState = ref.watch(customerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final UserProfile? profile = switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile,
      _ => null,
    };

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final int completedBookings = dashState.bookings
        .where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.reviewed || b.status == BookingStatus.paymentConfirmed)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryContainer,
              child: Text(
                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              profile.phoneNumber,
              style: TextStyle(fontSize: 16, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 32),

            // Stats
            Row(
              children: <Widget>[
                Expanded(child: _buildStatCard('Bookings', completedBookings.toString(), Icons.event_available, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Member Since', '${profile.createdAt.year}', Icons.workspace_premium, isDark)),
              ],
            ),
            const SizedBox(height: 32),

            // Settings List
            _buildSettingsTile(Icons.location_on_outlined, 'Saved Addresses', 'Manage your service locations', isDark),
            _buildSettingsTile(Icons.payment_outlined, 'Payment Methods', 'Manage cards and UPI', isDark),
            _buildSettingsTile(Icons.notifications_outlined, 'Notifications', 'App alert preferences', isDark),
            _buildSettingsTile(Icons.support_agent_outlined, 'Help & Support', 'Contact customer care', isDark),
            const SizedBox(height: 24),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: () {},
    );
  }
}
