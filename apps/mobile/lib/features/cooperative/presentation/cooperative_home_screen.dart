import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/worker_document.dart';
import '../../../data/models/worker_profile.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/cooperative_admin_controller.dart';

class CooperativeHomeScreen extends ConsumerStatefulWidget {
  const CooperativeHomeScreen({super.key});

  @override
  ConsumerState<CooperativeHomeScreen> createState() => _CooperativeHomeScreenState();
}

class _CooperativeHomeScreenState extends ConsumerState<CooperativeHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final CooperativeAdminState state = ref.watch(cooperativeAdminProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<CooperativeAdminState>(cooperativeAdminProvider,
        (CooperativeAdminState? prev, CooperativeAdminState next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Cooperative Operations',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            Text(
              'Primary Society Officer Portal',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Queue',
            onPressed: () => ref.read(cooperativeAdminProvider.notifier).loadWorkers(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Filter Tabs
          _buildFilterTabs(context, state),

          // Worker list or empty/loading state
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(cooperativeAdminProvider.notifier).loadWorkers();
                    },
                    child: state.workers.isEmpty
                        ? _buildEmptyState(context, state.activeFilter, isDark)
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: state.workers.length,
                            separatorBuilder: (BuildContext context, int i) => const SizedBox(height: 14),
                            itemBuilder: (BuildContext context, int index) {
                              final WorkerProfile worker = state.workers[index];
                              return _buildWorkerReviewCard(context, worker, isDark);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, CooperativeAdminState state) {
    final List<(String key, String label)> filters = <(String, String)>[
      ('pending', 'Pending (${state.pendingCount})'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
      ('all', 'All Roster'),
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (BuildContext context, int i) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final (String key, String label) = filters[index];
          final bool isSelected = state.activeFilter == key;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: AppColors.roleCooperative.withAlpha(30),
            side: BorderSide(
              color: isSelected ? AppColors.roleCooperative : Colors.transparent,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.roleCooperative : null,
            ),
            onSelected: (bool selected) {
              if (selected) {
                ref.read(cooperativeAdminProvider.notifier).setFilter(key);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkerReviewCard(BuildContext context, WorkerProfile worker, bool isDark) {
    final (Color badgeBg, Color badgeColor, String statusText) = switch (worker.verificationStatus) {
      WorkerVerificationStatus.approved => (
          AppColors.success.withAlpha(25),
          AppColors.success,
          'CERTIFIED'
        ),
      WorkerVerificationStatus.pending => (
          Colors.orange.withAlpha(25),
          Colors.orange.shade800,
          'PENDING'
        ),
      WorkerVerificationStatus.rejected => (
          AppColors.error.withAlpha(25),
          AppColors.error,
          'REJECTED'
        ),
      WorkerVerificationStatus.unsubmitted => (
          Colors.grey.withAlpha(25),
          Colors.grey,
          'UNSUBMITTED'
        ),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header: Avatar, Name, Status Badge
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.roleWorker.withAlpha(25),
                  child: Text(
                    worker.displayName.isNotEmpty ? worker.displayName[0].toUpperCase() : 'W',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.roleWorker),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        worker.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${worker.phoneNumber ?? "No phone"} • ${worker.experienceYears} yrs exp',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trade skills chips
            if (worker.skills.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: worker.skills.map((String skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),

            // Rejection reason callout if rejected
            if (worker.verificationStatus.isRejected &&
                worker.rejectionReason != null &&
                worker.rejectionReason!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withAlpha(40)),
                ),
                child: Text(
                  'Rejection reason: "${worker.rejectionReason}"',
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
            ],

            const Divider(height: 24),

            // Action row: Inspect KYC documents & Approve/Reject
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('View Documents'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showDocumentsDialog(context, worker),
              ),
            ),
            if (worker.verificationStatus != WorkerVerificationStatus.approved) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _promptRejectionReason(context, worker.id),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () =>
                          ref.read(cooperativeAdminProvider.notifier).approveWorker(worker.id),
                      child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String activeFilter, bool isDark) {
    final String title = activeFilter == 'pending'
        ? 'No Pending Verifications'
        : 'No Workers Found';
    final String message = activeFilter == 'pending'
        ? 'All submitted worker applications have been processed and certified.'
        : 'No worker profiles matched the "$activeFilter" filter criteria.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 56,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentsDialog(BuildContext context, WorkerProfile worker) async {
    final List<WorkerDocument> docs =
        await ref.read(cooperativeAdminProvider.notifier).loadWorkerDocuments(worker.id);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Submitted Verification Documents',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Worker: ${worker.displayName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No documents uploaded yet by this worker.'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (BuildContext context, int i) => const Divider(height: 14),
                  itemBuilder: (BuildContext context, int index) {
                    final WorkerDocument doc = docs[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.file_present_rounded, color: AppColors.primary),
                      ),
                      title: Text(
                        doc.documentType.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${doc.fileName} (${doc.formattedFileSize})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Verified Copy',
                          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _promptRejectionReason(BuildContext context, String workerId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Reject Verification Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Please specify the exact reason so the worker knows what to correct and resubmit:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Aadhaar card photo is blurred / ITI certificate date is illegible',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                final String reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  return;
                }
                Navigator.of(dialogCtx).pop();
                ref.read(cooperativeAdminProvider.notifier).rejectWorker(workerId, reason);
              },
              child: const Text('Confirm Rejection'),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of the Cooperative Operations portal?'),
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
  }
}
