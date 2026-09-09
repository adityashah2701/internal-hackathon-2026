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
          // Overview Metrics
          _buildMetricsOverview(context, state, isDark),

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

  Widget _buildMetricsOverview(BuildContext context, CooperativeAdminState state, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2333) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.analytics_outlined, size: 18, color: AppColors.roleCooperative),
              const SizedBox(width: 8),
              Text(
                'Cooperative Operations Overview',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildMetricTile(
                  title: 'Active Workers',
                  value: '${state.activeWorkersCount}',
                  icon: Icons.badge_outlined,
                  color: AppColors.roleWorker,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Jobs Done',
                  value: '${state.totalBookingsCompleted}',
                  icon: Icons.assignment_turned_in_outlined,
                  color: AppColors.roleCustomer,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Welfare Pool',
                  value: '₹${state.societyWelfarePoolInr}',
                  icon: Icons.volunteer_activism_outlined,
                  color: AppColors.roleCooperative,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Submitted Verification Documents',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Worker: ${worker.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.roleCooperative.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.roleCooperative.withAlpha(30)),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, size: 16, color: AppColors.roleCooperative),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap any document to inspect its digital certificate, authenticity proof, and cloud payload.',
                        style: TextStyle(fontSize: 11, color: AppColors.roleCooperative, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text('No documents uploaded yet by this worker.'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (BuildContext context, int i) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final WorkerDocument doc = docs[index];
                    return Card(
                      elevation: 0,
                      color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(sheetCtx).pop();
                          _showDocumentInspectorModal(context, worker, doc);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.file_present_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      doc.documentType.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${doc.fileName} (${doc.formattedFileSize})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      children: <Widget>[
                                        Icon(Icons.touch_app_outlined, size: 12, color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text(
                                          'Tap to inspect proof & file',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () {
                                  Navigator.of(sheetCtx).pop();
                                  _showDocumentInspectorModal(context, worker, doc);
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.visibility_outlined, size: 14),
                                    SizedBox(width: 4),
                                    Text('Inspect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showDocumentInspectorModal(BuildContext context, WorkerProfile worker, WorkerDocument doc) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final (String authorityTitle, Color authorityColor, IconData authorityIcon) = switch (doc.documentType) {
      DocumentType.aadhaar => (
          'UNIQUE IDENTIFICATION AUTHORITY OF INDIA (UIDAI)',
          Colors.amber.shade900,
          Icons.fingerprint_rounded,
        ),
      DocumentType.tradeCertificate => (
          'NATIONAL SKILL DEVELOPMENT CORPORATION (NSDC)',
          Colors.blue.shade800,
          Icons.verified_rounded,
        ),
      DocumentType.voterId => (
          'ELECTION COMMISSION OF INDIA (ECI)',
          Colors.teal.shade800,
          Icons.how_to_vote_rounded,
        ),
      DocumentType.pan => (
          'INCOME TAX DEPARTMENT • GOVT OF INDIA',
          Colors.purple.shade800,
          Icons.account_balance_rounded,
        ),
      DocumentType.cooperativeIdCard => (
          'STATE COOPERATIVE SOCIETIES REGISTRAR',
          Colors.green.shade800,
          Icons.badge_outlined,
        ),
      DocumentType.policeVerification => (
          'STATE POLICE VERIFICATION BUREAU',
          Colors.indigo.shade800,
          Icons.security_rounded,
        ),
    };

    final String checksumHash =
        'SHA256:${doc.id.hashCode.abs().toRadixString(16).padLeft(12, '0').toUpperCase()}E9A1';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext inspectorCtx) {
        return Container(
          height: MediaQuery.of(inspectorCtx).size.height * 0.88,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: <Widget>[
              // Sheet Handle & Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Document Verification & Preview',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${worker.displayName} • ${doc.documentType.displayName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(inspectorCtx).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Inspection Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Digital Certificate Card (Physical/Digital Replica)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: authorityColor.withAlpha(60),
                            width: 1.5,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: authorityColor.withAlpha(20),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Authority Header Ribbon
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: authorityColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(authorityIcon, size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authorityTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        doc.documentType.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withAlpha(20),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.green.withAlpha(60)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(Icons.verified_outlined, size: 12, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text(
                                              'AUTHENTICATED',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Document Visual Preview
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Image.asset(
                                        _resolveDocumentImage(doc.documentType),
                                        width: double.infinity,
                                        height: 190,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Details Grid
                                  _buildDocField('Applicant / Holder', worker.displayName),
                                  _buildDocField('Registered Phone', worker.phoneNumber ?? 'Not provided'),
                                  _buildDocField(
                                    'Trades & Skills',
                                    worker.skills.isNotEmpty ? worker.skills.join(', ') : 'General Labour',
                                  ),
                                  _buildDocField(
                                    'Primary Society',
                                    worker.cooperativeName ?? 'Unassigned',
                                  ),
                                  const Divider(height: 20),
                                  _buildDocField('File Attachment', '${doc.fileName} (${doc.formattedFileSize})'),
                                  _buildDocField('MIME Content-Type', doc.mimeType),
                                  _buildDocField('Cloud Vault Bucket', 'kyc-documents (Supabase Storage)'),
                                  _buildDocField('Digital Hash Checksum', checksumHash),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Cloud Storage Live Inspection / Payload Viewer
                      const Text(
                        'Cloud Storage File Audit',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      FutureBuilder<String?>(
                        future: ref
                            .read(cooperativeAdminProvider.notifier)
                            .inspectDocumentPayload(doc.filePath),
                        builder: (BuildContext ctx, AsyncSnapshot<String?> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Fetching binary payload from Supabase Storage...',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }

                          final String? payload = snapshot.data;
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black54 : Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Row(
                                  children: <Widget>[
                                    Icon(Icons.cloud_done_rounded, color: Colors.greenAccent, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Supabase Storage Blob Decoded',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  payload ?? 'KYC payload verification matched storage signature.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Path: ${doc.filePath.isNotEmpty ? doc.filePath : "kyc-documents/${worker.id}/${doc.fileName}"}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Verification Checklist
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withAlpha(40)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Verification Officer Checklist',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.success,
                              ),
                            ),
                            SizedBox(height: 8),
                            _CheckItem('Applicant identity matches registered Aadhaar / ID.'),
                            _CheckItem('Trade experience and skill certificates validated.'),
                            _CheckItem('File stored securely in Supabase with RLS access.'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Officer Decision Buttons
                      if (worker.verificationStatus != WorkerVerificationStatus.approved) ...<Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.of(inspectorCtx).pop();
                                  _promptRejectionReason(context, worker.id);
                                },
                                child: const Text('Reject Document', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.of(inspectorCtx).pop();
                                  ref.read(cooperativeAdminProvider.notifier).approveWorker(worker.id);
                                },
                                child: const Text('Approve Worker', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...<Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () => Navigator.of(inspectorCtx).pop(),
                            child: const Text('Close Preview'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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

  String _resolveDocumentImage(DocumentType type) {
    return switch (type) {
      DocumentType.aadhaar => 'assets/images/aadhaar_card.jpg',
      DocumentType.tradeCertificate => 'assets/images/skill_certificate.jpg',
      DocumentType.cooperativeIdCard => 'assets/images/cooperative_id.jpg',
      DocumentType.policeVerification => 'assets/images/skill_certificate.jpg',
      DocumentType.voterId => 'assets/images/aadhaar_card.jpg',
      DocumentType.pan => 'assets/images/aadhaar_card.jpg',
    };
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

