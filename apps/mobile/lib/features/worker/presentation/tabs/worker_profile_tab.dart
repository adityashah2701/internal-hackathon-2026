import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/models/worker_profile.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/worker_controller.dart';

class WorkerProfileTab extends ConsumerWidget {
  const WorkerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
    final WorkerDashboardState dashState = ref.watch(workerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final UserProfile? userProfile = switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile,
      _ => null,
    };

    if (userProfile == null || (dashState.isLoading && dashState.profile.id.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    final WorkerProfile workerProfile = dashState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryContainer,
              child: Text(
                userProfile.fullName.isNotEmpty ? userProfile.fullName[0].toUpperCase() : 'W',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userProfile.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  workerProfile.verificationStatus == WorkerVerificationStatus.approved
                      ? Icons.verified
                      : Icons.pending,
                  color: workerProfile.verificationStatus == WorkerVerificationStatus.approved
                      ? AppColors.success
                      : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  workerProfile.verificationStatus == WorkerVerificationStatus.approved
                      ? 'Verified Worker'
                      : 'Verification Pending',
                  style: TextStyle(
                    color: workerProfile.verificationStatus == WorkerVerificationStatus.approved
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workerProfile.skills.isNotEmpty ? workerProfile.skills.join(' • ') : 'No skills listed',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Text(
              workerProfile.serviceArea.isNotEmpty ? workerProfile.serviceArea : 'Area not specified',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildStat('⭐ 4.8', 'Rating'), // Mock rating for now
                _buildStat('${dashState.historicalBookings.length}', 'Jobs'),
                _buildStat('${workerProfile.experienceYears} Yrs', 'Experience'),
              ],
            ),
            const Divider(height: 48),
            _buildSection(
              title: 'Professional Details',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Daily Rate: ₹${workerProfile.dailyRateInr}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (workerProfile.bio.isNotEmpty) ...<Widget>[
                    const Text('About Me:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(workerProfile.bio, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ],
              ),
            ),
            const Divider(height: 48),
            _buildSection(
              title: 'Verification Documents',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dashState.documents.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text('${doc.documentType.displayName} uploaded'),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const Divider(height: 48),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: <Widget>[
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
