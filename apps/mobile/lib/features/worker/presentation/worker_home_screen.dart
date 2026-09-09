import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/cooperative_society.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/worker_document.dart';
import '../../../data/models/worker_profile.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/worker_controller.dart';

class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final WorkerDashboardState state = ref.watch(workerDashboardProvider);
    final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
    final UserProfile? userProfile = switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile,
      AuthOnboardingRequired(:final UserProfile? profile) => profile,
      _ => null,
    };
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen for errors or success
    ref.listen<WorkerDashboardState>(workerDashboardProvider, (WorkerDashboardState? prev, WorkerDashboardState next) {
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
        title: const Text(
          'Worker Workspace',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.roleWorker.withAlpha(25),
                  child: const Icon(Icons.person_rounded, color: AppColors.roleWorker),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user?.fullName.isNotEmpty == true ? user!.fullName : 'Cooperative Worker',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.phoneNumber.isNotEmpty == true ? user!.phoneNumber : 'Phone not provided',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.roleWorker.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'WORKER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.roleWorker,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
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
                const Text(
                  'Trade & Qualifications',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                if (!profile.verificationStatus.isApproved)
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    onPressed: () => _showEditSkillsModal(context, profile, societies),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Skills chips
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
                  return Chip(
                    label: Text(skill),
                    backgroundColor: AppColors.primary.withAlpha(18),
                    side: const BorderSide(color: AppColors.primary, width: 0.8),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            const Divider(height: 28),
            // Experience & Daily rate grid
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'EXPERIENCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.experienceYears} Years',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'BASE RATE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${profile.dailyRateInr} / day',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
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
                            'Shramik Kalyan Labour Cooperative Society',
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
      return OutlinedButton.icon(
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Application Under Review by Society'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: null,
      );
    }

    return FilledButton.icon(
      icon: state.isActionInProgress
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
  late final TextEditingController _dailyRateController;
  late final TextEditingController _serviceAreaController;
  late final TextEditingController _bioController;
  String? _selectedCooperativeId;

  @override
  void initState() {
    super.initState();
    _selectedSkills = Set<String>.from(widget.profile.skills);
    _experienceController = TextEditingController(text: widget.profile.experienceYears.toString());
    _dailyRateController = TextEditingController(text: widget.profile.dailyRateInr.toString());
    _serviceAreaController = TextEditingController(text: widget.profile.serviceArea);
    _bioController = TextEditingController(text: widget.profile.bio);
    _selectedCooperativeId = widget.profile.cooperativeId ?? widget.societies.firstOrNull?.id;
  }

  @override
  void dispose() {
    _experienceController.dispose();
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
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _dailyRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Daily Base Rate',
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
                  final int rate = int.tryParse(_dailyRateController.text.trim()) ?? 500;
                  ref.read(workerDashboardProvider.notifier).updateProfileDetails(
                        skills: _selectedSkills.toList(),
                        experienceYears: exp,
                        dailyRateInr: rate,
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
  String _sampleFileName = 'aadhaar_card_proof.pdf';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Upload KYC Document',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Select Document Type',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<DocumentType>(
            initialValue: _selectedType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
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
                  _sampleFileName = switch (val) {
                    DocumentType.aadhaar => 'aadhaar_card_proof.pdf',
                    DocumentType.tradeCertificate => 'iti_skill_certificate.pdf',
                    DocumentType.voterId => 'voter_id_proof.pdf',
                    DocumentType.pan => 'pan_card_proof.pdf',
                  };
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _sampleFileName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Format: PDF/JPEG • Storage: Supabase kyc-documents',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
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
                // Generate a realistic binary payload simulating the uploaded PDF/document
                final String mockContent = 'SAHAYOG_KYC_${_selectedType.name}_${DateTime.now().toIso8601String()}';
                final List<int> mockBytes = utf8.encode(mockContent);

                ref.read(workerDashboardProvider.notifier).uploadDocument(
                      documentType: _selectedType,
                      fileName: _sampleFileName,
                      bytes: mockBytes,
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
