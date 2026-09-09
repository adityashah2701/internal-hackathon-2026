import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/cooperative_society.dart';
import '../../../data/models/worker_document.dart';
import '../providers/verification_provider.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final GlobalKey<FormState> _basicInfoFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final WorkerVerificationWizardState wizard = ref.read(workerVerificationWizardProvider);
    _nameController = TextEditingController(text: wizard.fullName);
    _phoneController = TextEditingController(text: wizard.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onNextStep(int currentStep) {
    if (currentStep == 0) {
      if (!_basicInfoFormKey.currentState!.validate()) return;
      ref.read(workerVerificationWizardProvider.notifier).updateBasicInfo(
            fullName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          );
      ref.read(workerVerificationWizardProvider.notifier).goToStep(1);
    } else if (currentStep == 1) {
      ref.read(workerVerificationWizardProvider.notifier).goToStep(2);
    }
  }

  Future<void> _handleSubmit() async {
    final bool success =
        await ref.read(workerVerificationWizardProvider.notifier).submitVerificationWizard();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: <Widget>[
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Verification documents submitted! Your profile is now Under Review.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );

      // Redirect to Worker Home Screen as specified in requirement 5
      context.go(AppRoutes.workerDashboard);
    } else {
      final String? error = ref.read(workerVerificationWizardProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Submission failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final WorkerVerificationWizardState wizard = ref.watch(workerVerificationWizardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Worker Verification',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            tooltip: 'System Diagnostics',
            icon: const Icon(Icons.medical_services_outlined),
            onPressed: () => _showDiagnosticsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Stepper Progress Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Row(
                children: <Widget>[
                  _buildStepIndicator(0, 'Basic Info', wizard.currentStep),
                  _buildStepDivider(wizard.currentStep >= 1),
                  _buildStepIndicator(1, 'Doc Type', wizard.currentStep),
                  _buildStepDivider(wizard.currentStep >= 2),
                  _buildStepIndicator(2, 'Upload', wizard.currentStep),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: switch (wizard.currentStep) {
                  0 => _buildStep1BasicInfo(wizard),
                  1 => _buildStep2DocumentSelector(wizard),
                  _ => _buildStep3UploadAndSubmit(wizard),
                },
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  if (wizard.currentStep > 0) ...<Widget>[
                    OutlinedButton.icon(
                      onPressed: wizard.isUploading
                          ? null
                          : () => ref
                              .read(workerVerificationWizardProvider.notifier)
                              .goToStep(wizard.currentStep - 1),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: wizard.isUploading
                          ? null
                          : () {
                              if (wizard.currentStep < 2) {
                                _onNextStep(wizard.currentStep);
                              } else {
                                _handleSubmit();
                              }
                            },
                      child: wizard.isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              wizard.currentStep == 2 ? 'Upload & Submit for Review' : 'Continue',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, int currentStep) {
    final bool isCompleted = currentStep > stepIndex;
    final bool isActive = currentStep == stepIndex;

    final Color color = isCompleted
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : Colors.grey;

    return Expanded(
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool isDone) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isDone ? AppColors.success : Colors.grey.withValues(alpha: 0.3),
    );
  }

  // STEP 1: Basic Info
  Widget _buildStep1BasicInfo(WorkerVerificationWizardState wizard) {
    return Form(
      key: _basicInfoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Step 1: Worker Identification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Provide your legal personal identification details and affiliate with your local registered cooperative society.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // Full Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name (as per Govt ID) *',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (String? val) {
              if (val == null || val.trim().isEmpty) return 'Full name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Number
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '+91 ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (String? val) {
              if (val == null || val.trim().isEmpty) return 'Phone number is required';
              if (val.trim().length < 10) return 'Enter a valid 10-digit phone number';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Cooperative Society Affiliation Dropdown
          DropdownButtonFormField<String>(
            value: wizard.selectedCooperativeId ??
                (wizard.societies.isNotEmpty ? wizard.societies.first.id : null),
            decoration: InputDecoration(
              labelText: 'Cooperative Society Affiliation *',
              prefixIcon: const Icon(Icons.corporate_fare_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: wizard.societies.map((CooperativeSociety s) {
              return DropdownMenuItem<String>(
                value: s.id,
                child: Text(
                  '${s.name} (${s.district})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (String? val) {
              if (val != null) {
                ref.read(workerVerificationWizardProvider.notifier).updateBasicInfo(
                      fullName: _nameController.text.trim(),
                      phoneNumber: _phoneController.text.trim(),
                      cooperativeId: val,
                    );
              }
            },
          ),
          const SizedBox(height: 24),

          // Cooperative trust badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Direct Cooperative Protection',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Affiliated workers are covered by state welfare board benefits, cooperative emergency pool, and transparent commission-free payouts.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Document Selector
  Widget _buildStep2DocumentSelector(WorkerVerificationWizardState wizard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Step 2: Verification Document Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the official identity or trade qualification document you wish to present to the cooperative society.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        _buildDocumentTypeCard(
          type: DocumentType.aadhaar,
          title: 'Aadhaar Card / National Identity',
          subtitle: 'Official government proof of identity & address',
          icon: Icons.fingerprint_rounded,
          selected: wizard.selectedDocType == DocumentType.aadhaar,
        ),
        const SizedBox(height: 12),
        _buildDocumentTypeCard(
          type: DocumentType.tradeCertificate,
          title: 'Skill / Trade Certificate',
          subtitle: 'ITI, NSDC, or government vocational trade certification',
          icon: Icons.workspace_premium_rounded,
          selected: wizard.selectedDocType == DocumentType.tradeCertificate,
        ),
        const SizedBox(height: 12),
        _buildDocumentTypeCard(
          type: DocumentType.cooperativeIdCard,
          title: 'Cooperative Membership Card',
          subtitle: 'Registered union or society membership smart card / booklet',
          icon: Icons.badge_outlined,
          selected: wizard.selectedDocType == DocumentType.cooperativeIdCard,
        ),
        const SizedBox(height: 12),
        _buildDocumentTypeCard(
          type: DocumentType.policeVerification,
          title: 'Police Verification Certificate',
          subtitle: 'Clearance certificate issued by local police station',
          icon: Icons.security_rounded,
          selected: wizard.selectedDocType == DocumentType.policeVerification,
        ),
      ],
    );
  }

  Widget _buildDocumentTypeCard({
    required DocumentType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(workerVerificationWizardProvider.notifier).selectDocumentType(type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
          color: selected ? AppColors.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? AppColors.primary : Colors.grey[700]),
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
                      fontSize: 14,
                      color: selected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Radio<DocumentType>(
              value: type,
              groupValue: ref.watch(workerVerificationWizardProvider).selectedDocType,
              activeColor: AppColors.primary,
              onChanged: (DocumentType? val) {
                if (val != null) {
                  ref.read(workerVerificationWizardProvider.notifier).selectDocumentType(val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: Upload & Capture
  Widget _buildStep3UploadAndSubmit(WorkerVerificationWizardState wizard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Step 3: Capture & Document Upload',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload your ${wizard.selectedDocType.displayName}. Files are securely stored in the worker-documents bucket.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // Upload Preview / Action Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: wizard.hasFile ? AppColors.success : Colors.grey.withValues(alpha: 0.3),
              width: wizard.hasFile ? 2 : 1,
            ),
            color: wizard.hasFile
                ? AppColors.success.withValues(alpha: 0.04)
                : Colors.grey.withValues(alpha: 0.02),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                wizard.hasFile ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                size: 56,
                color: wizard.hasFile ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                wizard.hasFile
                    ? 'Document Ready for Supabase Storage'
                    : 'Select or Capture Document',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                wizard.hasFile
                    ? wizard.fileName ?? 'Selected Document'
                    : 'Supported: PDF, JPG, PNG (Max 10MB)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: wizard.hasFile ? AppColors.success : Colors.grey[600],
                  fontWeight: wizard.hasFile ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: wizard.isUploading
                        ? null
                        : () => ref
                            .read(workerVerificationWizardProvider.notifier)
                            .simulateDocumentCapture(),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Capture / Simulate Camera'),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (wizard.isUploading) ...<Widget>[
          const SizedBox(height: 24),
          Text(
            'Uploading to worker-documents storage bucket... ${(wizard.uploadProgress * 100).toInt()}%',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: wizard.uploadProgress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
        ],

        const SizedBox(height: 24),
        // Summary of submission
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Application Summary',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Divider(),
                _buildSummaryRow('Worker Name', wizard.fullName),
                _buildSummaryRow('Phone', '+91 ${wizard.phoneNumber}'),
                _buildSummaryRow(
                  'Cooperative',
                  wizard.societies
                      .firstWhere(
                        (s) => s.id == wizard.selectedCooperativeId,
                        orElse: () => CooperativeSociety.fallbackSocieties.first,
                      )
                      .name,
                ),
                _buildSummaryRow('Document', wizard.selectedDocType.displayName),
                _buildSummaryRow(
                  'Target Status',
                  'Under Review (Pending Verification)',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiagnosticsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final DiagnosticsState diag = ref.watch(diagnosticsProvider);
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Supabase Connection Diagnostics',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      diag.connectivityStatus == SupabaseConnectivityStatus.connected
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: diag.connectivityStatus == SupabaseConnectivityStatus.connected
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    title: Text('Status: ${diag.connectivityStatus.name}'),
                    subtitle: Text('Host: ${diag.sanitizedHost}\nVersion: ${diag.appVersion}'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(diagnosticsProvider.notifier).checkConnectivity();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recheck Connection'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
