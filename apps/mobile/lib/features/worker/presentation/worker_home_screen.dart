import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/cooperative_society.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/worker_document.dart';
import '../../../data/models/worker_profile.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../common/presentation/notification_screen.dart';
import '../controllers/worker_controller.dart';

class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Background status check every 4 seconds to detect Cooperative Admin verification approval
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final WorkerVerificationStatus status =
          ref.read(workerDashboardProvider).profile.verificationStatus;
      if (status.isPending) {
        ref.read(workerDashboardProvider.notifier).loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WorkerDashboardState state = ref.watch(workerDashboardProvider);
    final UserProfile? userProfile = ref.watch(authControllerProvider).value is AuthAuthenticated
        ? (ref.watch(authControllerProvider).value as AuthAuthenticated).profile
        : null;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<WorkerDashboardState>(workerDashboardProvider,
        (WorkerDashboardState? prev, WorkerDashboardState next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Worker Workspace',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Status',
              onPressed: () => ref.read(workerDashboardProvider.notifier).loadDashboard(),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
              onPressed: () => _confirmSignOut(context),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Widget>[
              Tab(text: 'Profile & Setup'),
              Tab(text: 'Available Jobs'),
              Tab(text: 'Active Jobs'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: <Widget>[
                  // TAB 1: Profile & Setup
                  RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(workerDashboardProvider.notifier).loadDashboard();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // 1. Worker Identity & Verification Status Banner
                          _buildVerificationBanner(context, state.profile, isDark),
                          const SizedBox(height: 20),

                          // 2. Personal Info Card
                          _buildPersonalInfoCard(context, userProfile, state.profile, isDark),
                          const SizedBox(height: 20),

                          // 3. Trade Skills & Experience Card
                          _buildTradeSkillsCard(context, state.profile, state.societies, isDark),
                          const SizedBox(height: 20),

                          // 4. KYC & Skill Documents Section
                          _buildDocumentsCard(context, state.documents, state.profile.verificationStatus, isDark),
                          const SizedBox(height: 28),

                          // 5. Verification Action CTA
                          _buildPrimaryActionCTA(context, state),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // TAB 2: Available Jobs
                  _buildAvailableJobsTab(context, state, isDark),

                  // TAB 3: Active Jobs
                  _buildActiveJobsTab(context, state, isDark),

                  // TAB 4: History
                  _buildHistoryTab(context, state, isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildVerificationBanner(BuildContext context, WorkerProfile profile, bool isDark) {
    final (Color bannerBg, Color borderColor, Color textColor, IconData icon, String title, String subtitle) =
        switch (profile.verificationStatus) {
      WorkerVerificationStatus.unsubmitted => (
          isDark ? const Color(0xFF2D2416) : const Color(0xFFFFFBEB),
          isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
          const Color(0xFFD97706),
          Icons.shield_outlined,
          'Verification Required',
          'Complete your trade details and upload identity documents to receive verified dispatch jobs.'
        ),
      WorkerVerificationStatus.pending => (
          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          const Color(0xFF2563EB),
          Icons.pending_actions_rounded,
          'Verification In Review',
          'Your documents are under review by your Primary Cooperative Society. Decision usually takes 24 hours.'
        ),
      WorkerVerificationStatus.approved => (
          isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
          isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
          const Color(0xFF059669),
          Icons.verified_rounded,
          'Verified Cooperative Member',
          'Certified by ${profile.cooperativeName ?? "Cooperative Society"}. You are eligible for automated dispatch & welfare dividends.'
        ),
      WorkerVerificationStatus.rejected => (
          isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
          isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
          const Color(0xFFDC2626),
          Icons.error_outline_rounded,
          'Action Required: Resubmit Verification',
          profile.rejectionReason != null && profile.rejectionReason!.isNotEmpty
              ? 'Reason: "${profile.rejectionReason}"'
              : 'Your documents did not pass verification. Please update and resubmit.'
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: textColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(
      BuildContext context, UserProfile? user, WorkerProfile profile, bool isDark) {
    final String primaryTrade = profile.skills.isNotEmpty ? profile.skills.first : 'Trade Not Set';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Worker identity & role badge
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.roleWorker.withAlpha(25),
                  child: const Icon(Icons.person_rounded, color: AppColors.roleWorker, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.fullName.isNotEmpty == true ? user!.fullName : 'Cooperative Worker',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        primaryTrade,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Cooperative Verification Badge
                if (profile.verificationStatus.isApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'FEDERATION CERTIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile.verificationStatus.displayName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 28),

            // Real-Time On-Duty / Off-Duty Availability Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: profile.isAvailable
                    ? AppColors.success.withAlpha(15)
                    : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: profile.isAvailable ? AppColors.success : Colors.grey.withAlpha(60),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    profile.isAvailable ? Icons.bolt_rounded : Icons.bedtime_outlined,
                    color: profile.isAvailable ? AppColors.success : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile.isAvailable ? 'STATUS: ON-DUTY' : 'STATUS: OFF-DUTY',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: profile.isAvailable ? AppColors.success : Colors.grey[700],
                          ),
                        ),
                        Text(
                          profile.isAvailable
                              ? 'Broadcasting live availability for cooperative service dispatch'
                              : 'Off-duty: You will not receive customer requests right now',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: profile.isAvailable,
                    activeTrackColor: AppColors.success,
                    activeThumbColor: Colors.white,
                    onChanged: (bool val) {
                      ref.read(workerDashboardProvider.notifier).toggleAvailability(val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeSkillsCard(
      BuildContext context, WorkerProfile profile, List<CooperativeSociety> societies, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Trade Skills & Certification',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  onPressed: () => _showEditSkillsModal(context, profile, societies),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Skills chips with certified status indicator
            if (profile.skills.isEmpty)
              const Text(
                'No skills selected. Tap Edit to add your primary trades.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.skills.map((String skill) {
                  final bool isCert = profile.verificationStatus.isApproved;
                  return Chip(
                    avatar: Icon(
                      isCert
                          ? Icons.verified_rounded
                          : profile.verificationStatus.isPending
                              ? Icons.schedule_rounded
                              : Icons.info_outline_rounded,
                      size: 16,
                      color: isCert
                          ? AppColors.success
                          : profile.verificationStatus.isPending
                              ? AppColors.warning
                              : Colors.grey,
                    ),
                    label: Text(
                      '$skill (${isCert ? "Verified" : profile.verificationStatus.isPending ? "Under Review" : "Unverified"})',
                    ),
                    backgroundColor: AppColors.primary.withAlpha(15),
                    side: const BorderSide(color: AppColors.primary, width: 0.8),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  );
                }).toList(),
              ),
            const Divider(height: 28),
            // Experience, Hourly Rate, and Daily rate grid
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'EXPERIENCE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.experienceYears} Years',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'HOURLY CHARGE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${profile.hourlyRateInr} / hr',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'DAILY BASE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${profile.dailyRateInr} / day',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Primary Cooperative Society Affiliation
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'PRIMARY COOPERATIVE SOCIETY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Icon(Icons.apartment_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        profile.cooperativeName ??
                            societies.firstOrNull?.name ??
                            'Not Assigned',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard(
      BuildContext context, List<WorkerDocument> documents, WorkerVerificationStatus status, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'KYC & Trade Documents',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                if (!status.isApproved)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text('Upload'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showUploadDocumentModal(context),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Aadhaar or Govt ID proof and skill/trade certification are required.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            if (documents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.folder_open_rounded,
                      size: 36,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No documents uploaded yet.',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Upload" above to attach your Aadhaar card or ITI certificate.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documents.length,
                separatorBuilder: (BuildContext context, int i) => const Divider(height: 16),
                itemBuilder: (BuildContext context, int index) {
                  final WorkerDocument doc = documents[index];
                  return Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              doc.documentType.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${doc.fileName} • ${doc.formattedFileSize}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!status.isApproved)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          tooltip: 'Remove document',
                          onPressed: () {
                            ref.read(workerDashboardProvider.notifier).deleteDocument(doc.id, doc.filePath);
                          },
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionCTA(BuildContext context, WorkerDashboardState state) {
    if (state.profile.verificationStatus.isApproved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withAlpha(50)),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.radar_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Dispatch Radar Active',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Listening for local customer bookings in your service area.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (state.profile.verificationStatus.isPending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: const Text(
              'Under Review • Tap to Refresh Status',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            onPressed: () => ref.read(workerDashboardProvider.notifier).loadDashboard(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your documents have been submitted to the Cooperative Society. Tap above anytime or pull down to check updated status.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    return FilledButton.icon(
      icon: state.isActionInProgress
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
            )
          : const Icon(Icons.send_rounded),
      label: Text(
        state.profile.verificationStatus.isRejected
            ? 'Resubmit Verification'
            : 'Submit for Cooperative Verification',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: state.isActionInProgress
          ? null
          : () => ref.read(workerDashboardProvider.notifier).submitForVerification(),
    );
  }

  void _showEditSkillsModal(
      BuildContext context, WorkerProfile profile, List<CooperativeSociety> societies) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetCtx) {
        return _EditTradeSkillsSheet(profile: profile, societies: societies);
      },
    );
  }

  void _showUploadDocumentModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetCtx) {
        return const _UploadDocumentSheet();
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of the Worker Workspace?'),
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
  // --- JOB TABS ---

  Widget _buildAvailableJobsTab(BuildContext context, WorkerDashboardState state, bool isDark) {
    if (state.profile.verificationStatus != WorkerVerificationStatus.approved) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'You must be verified by a cooperative to receive dispatch jobs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      );
    }

    if (!state.profile.isAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.work_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'You are currently OFF-DUTY.\nToggle your status in Profile to receive jobs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(workerDashboardProvider.notifier).loadDashboard(),
      child: state.availableBookings.isEmpty
          ? Center(
              child: Text(
                'No new jobs in your area matching your skills.',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.availableBookings.length,
              itemBuilder: (BuildContext context, int index) {
                final Booking booking = state.availableBookings[index];
                return _buildBookingCard(
                  context,
                  booking: booking,
                  isDark: isDark,
                  primaryActionText: 'Accept Job',
                  onPrimaryAction: () => ref.read(workerDashboardProvider.notifier).acceptBooking(booking.id),
                );
              },
            ),
    );
  }

  Widget _buildActiveJobsTab(BuildContext context, WorkerDashboardState state, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => ref.read(workerDashboardProvider.notifier).loadDashboard(),
      child: state.activeBookings.isEmpty
          ? Center(
              child: Text(
                'No active jobs.',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.activeBookings.length,
              itemBuilder: (BuildContext context, int index) {
                final Booking booking = state.activeBookings[index];
                return _buildBookingCard(
                  context,
                  booking: booking,
                  isDark: isDark,
                  primaryActionText: booking.status == BookingStatus.accepted ? 'Start Job' : 'Complete Job',
                  onPrimaryAction: () {
                    if (booking.status == BookingStatus.accepted) {
                      ref.read(workerDashboardProvider.notifier).startJob(booking.id);
                    } else if (booking.status == BookingStatus.inProgress) {
                      ref.read(workerDashboardProvider.notifier).completeJob(booking.id);
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, WorkerDashboardState state, bool isDark) {
    final Iterable<Booking> completedBookings = state.historicalBookings.where(
      (Booking b) => b.status == BookingStatus.completed || b.status == BookingStatus.paymentConfirmed || b.status == BookingStatus.reviewed,
    );
    final int totalEarnings = completedBookings.fold<int>(0, (int sum, Booking b) => sum + (b.totalAmount - b.welfareFee));
    final int totalWelfare = completedBookings.fold<int>(0, (int sum, Booking b) => sum + b.welfareFee);

    return RefreshIndicator(
      onRefresh: () => ref.read(workerDashboardProvider.notifier).loadDashboard(),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  const Text('Total Net Earnings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('₹$totalEarnings', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          const Text('Jobs Completed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('${completedBookings.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.3)),
                      Column(
                        children: <Widget>[
                          const Text('Welfare Contributed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('₹$totalWelfare', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.historicalBookings.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No completed or cancelled jobs yet.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return _buildBookingCard(
                      context,
                      booking: state.historicalBookings[index],
                      isDark: isDark,
                    );
                  },
                  childCount: state.historicalBookings.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context, {
    required Booking booking,
    required bool isDark,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
  }) {
    final Color bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color borderColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  booking.trackingCode,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.status.isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: booking.status.isActive ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  booking.serviceTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.serviceAddress,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.scheduledDate.toLocal().toString().split(' ')[0]} | ${booking.timeSlot}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (primaryActionText != null && onPrimaryAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: onPrimaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(primaryActionText, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditTradeSkillsSheet extends ConsumerStatefulWidget {
  const _EditTradeSkillsSheet({
    required this.profile,
    required this.societies,
  });

  final WorkerProfile profile;
  final List<CooperativeSociety> societies;

  @override
  ConsumerState<_EditTradeSkillsSheet> createState() => _EditTradeSkillsSheetState();
}

class _EditTradeSkillsSheetState extends ConsumerState<_EditTradeSkillsSheet> {
  static const List<String> _availableTrades = <String>[
    'Electrician',
    'Plumber',
    'Carpenter',
    'Mason / Tiler',
    'Painter',
    'Welder',
    'Appliance Repair',
    'HVAC Technician',
    'Solar Installer',
  ];

  late final Set<String> _selectedSkills;
  late final TextEditingController _experienceController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _dailyRateController;
  late final TextEditingController _serviceAreaController;
  late final TextEditingController _bioController;
  String? _selectedCooperativeId;

  @override
  void initState() {
    super.initState();
    _selectedSkills = Set<String>.from(widget.profile.skills);
    _experienceController = TextEditingController(text: widget.profile.experienceYears.toString());
    _hourlyRateController = TextEditingController(text: widget.profile.hourlyRateInr.toString());
    _dailyRateController = TextEditingController(text: widget.profile.dailyRateInr.toString());
    _serviceAreaController = TextEditingController(text: widget.profile.serviceArea);
    _bioController = TextEditingController(text: widget.profile.bio);
    _selectedCooperativeId = widget.profile.cooperativeId ?? widget.societies.firstOrNull?.id;
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _serviceAreaController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Edit Trade & Qualifications',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Trade Skills',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTrades.map((String trade) {
                final bool isSelected = _selectedSkills.contains(trade);
                return FilterChip(
                  label: Text(trade),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedSkills.add(trade);
                      } else {
                        _selectedSkills.remove(trade);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Years of Exp',
                      suffixText: 'yrs',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hourlyRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hourly Rate',
                      prefixText: '₹ ',
                      suffixText: '/hr',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _dailyRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Daily Rate',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _serviceAreaController,
              decoration: const InputDecoration(
                labelText: 'Service Area / Localities',
                hintText: 'e.g. Pune Central, Hadapsar, Kothrud',
              ),
            ),
            const SizedBox(height: 14),
            // Cooperative Society Dropdown
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedCooperativeId,
              decoration: const InputDecoration(
                labelText: 'Affiliated Cooperative Society',
              ),
              items: widget.societies.map((CooperativeSociety s) {
                return DropdownMenuItem<String>(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (String? val) {
                setState(() => _selectedCooperativeId = val);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final int exp = int.tryParse(_experienceController.text.trim()) ?? 0;
                  final int hourly = int.tryParse(_hourlyRateController.text.trim()) ?? 150;
                  final int daily = int.tryParse(_dailyRateController.text.trim()) ?? 500;
                  ref.read(workerDashboardProvider.notifier).updateSkillProfile(
                        skills: _selectedSkills.toList(),
                        experienceYears: exp,
                        hourlyRateInr: hourly,
                        dailyRateInr: daily,
                      );
                  ref.read(workerDashboardProvider.notifier).updateProfileDetails(
                        skills: _selectedSkills.toList(),
                        experienceYears: exp,
                        dailyRateInr: daily,
                        serviceArea: _serviceAreaController.text.trim(),
                        bio: _bioController.text.trim(),
                        cooperativeId: _selectedCooperativeId,
                      );
                  Navigator.of(context).pop();
                },
                child: const Text('Save Trade Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadDocumentSheet extends ConsumerStatefulWidget {
  const _UploadDocumentSheet();

  @override
  ConsumerState<_UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<_UploadDocumentSheet> {
  DocumentType _selectedType = DocumentType.aadhaar;
  String _selectedFileName = 'aadhaar_card_proof.pdf';

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload KYC / Certification Document',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Uploaded documents are securely saved to the cooperative vault for society verification.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<DocumentType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Select Document Type',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            items: DocumentType.values.map((DocumentType type) {
              return DropdownMenuItem<DocumentType>(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (DocumentType? val) {
              if (val != null) {
                setState(() {
                  _selectedType = val;
                  _selectedFileName = switch (val) {
                    DocumentType.aadhaar => 'aadhaar_card_proof.pdf',
                    DocumentType.pan => 'pan_card_copy.pdf',
                    DocumentType.tradeCertificate => 'national_trade_cert.pdf',
                    DocumentType.policeVerification => 'police_clearance_cert.pdf',
                    DocumentType.cooperativeIdCard => 'cooperative_membership_card.pdf',
                    DocumentType.voterId => 'voter_id_proof.pdf',
                  };
                });
              }
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.attach_file_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Selected Document File',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        _selectedFileName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Upload to Supabase Storage'),
              onPressed: () {
                final String docContent = 'SAHAYOG_KYC_${_selectedType.name}_${DateTime.now().toIso8601String()}';
                final List<int> docBytes = utf8.encode(docContent);

                ref.read(workerDashboardProvider.notifier).uploadDocument(
                      documentType: _selectedType,
                      fileName: _selectedFileName,
                      bytes: docBytes,
                      mimeType: 'application/pdf',
                    );
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
