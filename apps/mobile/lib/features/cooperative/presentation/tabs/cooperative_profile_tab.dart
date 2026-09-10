import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_profile.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/cooperative_admin_controller.dart';

class CooperativeProfileTab extends ConsumerWidget {
  const CooperativeProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
    final CooperativeAdminState state = ref.watch(cooperativeAdminProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final UserProfile? userProfile = switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile,
      _ => null,
    };

    if (userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooperative Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            CircleAvatar(
              radius: 48,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.roleCooperative.withValues(alpha: 0.2),
              child: Text(
                userProfile.fullName.isNotEmpty ? userProfile.fullName[0].toUpperCase() : 'C',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.roleCooperative),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userProfile.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Primary Society Administrator',
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.account_balance, color: AppColors.roleCooperative),
                    title: const Text('Cooperative Welfare Pool'),
                    trailing: Text(
                      '₹${state.societyWelfarePoolInr}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.roleCooperative),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.group, color: AppColors.roleCooperative),
                    title: const Text('Registered Workers'),
                    trailing: Text(
                      '${state.workers.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext dialogCtx) {
                      return AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out of the Cooperative Portal?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(dialogCtx).pop();
                              ref.read(authControllerProvider.notifier).signOut();
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
