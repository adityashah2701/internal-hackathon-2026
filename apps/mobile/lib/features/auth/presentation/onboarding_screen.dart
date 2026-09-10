import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_role.dart';
import '../../common/presentation/widgets/map_location_picker_modal.dart';
import '../../common/presentation/widgets/profile_photo_picker.dart';
import '../controllers/auth_controller.dart';
import '../controllers/registration_draft_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _customerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _workerFormKey = GlobalKey<FormState>();

  // Role selection: 0 = Role Selection, 1 = Role Form (Customer or Worker), 2 = Review & Confirm
  UserRole _selectedRole = UserRole.customer;
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Shared User Details
  late final TextEditingController _fullNameController;
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Uint8List? _profilePhotoJpgBytes;
  String _preferredLanguage = 'English';

  // Customer Onboarding Specific
  final TextEditingController _customerAddressController = TextEditingController(
    text: 'Model Colony, Shivaji Nagar, Pune - 411016',
  );
  String _customerHouseFlat = '';
  String _customerBuilding = '';
  String _customerLandmark = '';
  double _customerLat = 18.5314;
  double _customerLng = 73.8446;

  // Worker Onboarding Specific
  String _workerTrade = 'Electrician';
  int _experienceYears = 3;
  final TextEditingController _workerPreferredAreasController = TextEditingController(
    text: 'Kothrud, Shivaji Nagar, Deccan, Pune',
  );
  bool _workerAvailableNow = true;
  final TextEditingController _workerUpiController = TextEditingController(text: 'worker@okaxis');
  String _uploadedDocName = 'aadhaar_card_scan.jpg';
  bool _hasUploadedDoc = true;

  final List<String> _languages = <String>[
    'English',
    'हिंदी (Hindi)',
    'मराठी (Marathi)',
    'ગુજરાતી (Gujarati)',
    'ಕನ್ನಡ (Kannada)',
  ];

  final List<String> _tradeOptions = <String>[
    'Electrician',
    'Plumber',
    'Carpenter',
    'Mason / Construction',
    'Painter',
    'Appliance Repair',
    'Housekeeper / Cleaner',
  ];

  @override
  void initState() {
    super.initState();
    final RegistrationDraft draft = ref.read(registrationDraftProvider);
    final AppAuthState? authState = ref.read(authControllerProvider).value;

    String initialName = draft.fullName;
    String initialEmail = draft.email;

    if (initialName.isEmpty && authState is AuthOnboardingRequired) {
      if (authState.profile != null) {
        initialName = authState.profile!.fullName;
      }
      initialEmail = authState.user.email ?? '';
    }

    _fullNameController = TextEditingController(text: initialName);
    _emailController.text = initialEmail;

    if (draft.phoneNumber.isNotEmpty) {
      _phoneNumberController.text = draft.phoneNumber;
    }
    if (draft.role == UserRole.worker) {
      _selectedRole = UserRole.worker;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _customerAddressController.dispose();
    _workerPreferredAreasController.dispose();
    _workerUpiController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _handleNextFromRoleSelection() {
    _goToStep(1);
  }

  void _handleNextFromForm() {
    if (_selectedRole == UserRole.customer) {
      if (!_customerFormKey.currentState!.validate()) return;
    } else {
      if (!_workerFormKey.currentState!.validate()) return;
    }
    _goToStep(2);
  }

  void _handleFinishOnboarding() {
    final RegistrationDraft draft = ref.read(registrationDraftProvider);
    final AppAuthState? authState = ref.read(authControllerProvider).value;

    if (draft.email.isNotEmpty && draft.password.isNotEmpty) {
      // Deferred registration: only now write user & complete profile to Supabase database!
      final RegistrationDraft fullDraft = draft.copyWith(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        role: _selectedRole,
        preferredLanguage: _preferredLanguage,
        address: _selectedRole == UserRole.worker
            ? _workerPreferredAreasController.text.trim()
            : _customerAddressController.text.trim(),
        houseFlatNumber: _customerHouseFlat,
        buildingName: _customerBuilding,
        landmark: _customerLandmark,
        latitude: _customerLat,
        longitude: _customerLng,
        trade: _workerTrade,
        experienceYears: _experienceYears,
        workerUpi: _workerUpiController.text.trim(),
        profilePhotoBytes: _profilePhotoJpgBytes,
      );

      ref.read(authControllerProvider.notifier).registerAndCompleteOnboarding(draft: fullDraft);
    } else if (authState is AuthOnboardingRequired) {
      // Existing signed-in user completing onboarding
      ref.read(authControllerProvider.notifier).completeOnboarding(
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneNumberController.text.trim(),
            role: _selectedRole,
          );
    } else {
      ref.read(authControllerProvider.notifier).completeOnboarding(
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneNumberController.text.trim(),
            role: _selectedRole,
          );
    }
  }

  Future<void> _openMapPicker(bool isWorker) async {
    final String initialAddr = isWorker
        ? _workerPreferredAreasController.text.trim()
        : _customerAddressController.text.trim();

    final PickedLocationResult? result = await MapLocationPickerModal.show(
      context,
      initialAddress: initialAddr,
      initialHouseFlat: _customerHouseFlat,
      initialBuilding: _customerBuilding,
      initialLandmark: _customerLandmark,
      initialLat: _customerLat,
      initialLng: _customerLng,
    );

    if (result != null) {
      setState(() {
        _customerHouseFlat = result.houseFlatNumber;
        _customerBuilding = result.buildingName;
        _customerLandmark = result.landmark;

        if (isWorker) {
          _workerPreferredAreasController.text = result.fullFormattedAddress.isNotEmpty
              ? result.fullFormattedAddress
              : result.address;
        } else {
          _customerAddressController.text = result.fullFormattedAddress.isNotEmpty
              ? result.fullFormattedAddress
              : result.address;
          _customerLat = result.latitude;
          _customerLng = result.longitude;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppAuthState> authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.isLoading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<AppAuthState>>(authControllerProvider,
        (AsyncValue<AppAuthState>? prev, AsyncValue<AppAuthState> next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final double progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: isLoading ? null : () => _goToStep(_currentStep - 1),
              )
            : null,
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps: ${_getStepTitle()}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Sign Out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Linear Progress Bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              _selectedRole == UserRole.worker ? AppColors.roleWorker : AppColors.primary,
            ),
          ),

          // Multi-step PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _buildRoleSelectionStep(context),
                _selectedRole == UserRole.worker
                    ? _buildWorkerOnboardingStep(context)
                    : _buildCustomerOnboardingStep(context),
                _buildReviewAndSubmitStep(context, isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Role Selection';
      case 1:
        return _selectedRole == UserRole.worker ? 'Worker Onboarding' : 'Customer Onboarding';
      case 2:
        return 'Review & Confirm';
      default:
        return '';
    }
  }

  // =========================================================================
  // STEP 1: ROLE SELECTION (Page 1)
  // =========================================================================
  Widget _buildRoleSelectionStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Join Sahayog Cooperative',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select how you wish to register on the federation platform.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),

          // Customer Card
          _SimpleRoleCard(
            title: 'Customer',
            subtitle: 'Hire verified workers, schedule services & transparent pricing',
            icon: Icons.shopping_bag_outlined,
            accentColor: AppColors.roleCustomer,
            isSelected: _selectedRole == UserRole.customer,
            onTap: () => setState(() => _selectedRole = UserRole.customer),
          ),
          const SizedBox(height: 14),

          // Worker Card
          _SimpleRoleCard(
            title: 'Worker / Service Partner',
            subtitle: 'Join trade cooperative, accept direct jobs & gain welfare coverage',
            icon: Icons.engineering_outlined,
            accentColor: AppColors.roleWorker,
            isSelected: _selectedRole == UserRole.worker,
            onTap: () => setState(() => _selectedRole = UserRole.worker),
          ),
          const SizedBox(height: 20),

          // Cooperative Verifier notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Worker Verifier and Cooperative Officer roles are appointed under society bylaws by the district federation.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _handleNextFromRoleSelection,
              style: FilledButton.styleFrom(
                backgroundColor: _selectedRole == UserRole.worker ? AppColors.roleWorker : AppColors.primary,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Continue to Profile Setup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: CUSTOMER ONBOARDING (Page 2)
  // Name, Phone/email, Profile photo, Address/location (map), Preferred language
  // =========================================================================
  Widget _buildCustomerOnboardingStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 20),
      child: Form(
        key: _customerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Customer Profile Setup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in your details to hire cooperative tradespeople nearby.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Profile photo picker with automatic JPG conversion & default avatar fallback
            ProfilePhotoPicker(
              fallbackName: _fullNameController.text,
              initialImageBytes: _profilePhotoJpgBytes,
              isWorker: false,
              onPhotoChanged: (Uint8List? bytes, String? base64) {
                _profilePhotoJpgBytes = bytes;
              },
            ),
            const SizedBox(height: 20),

            // Full Name Input
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g. Ramesh Kumar',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (String? val) {
                if (val == null || val.trim().isEmpty) return 'Please enter your full legal name.';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Phone Number Input
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                hintText: '98765 43210',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '+91',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(height: 20, width: 1, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                ),
              ),
              validator: (String? val) {
                if (val == null || val.trim().isEmpty) return 'Please enter your phone number.';
                final String digits = val.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) return 'Phone number must have at least 10 digits.';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address (Optional)',
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Address & Map Location Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Service Address & Location *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                TextButton.icon(
                  onPressed: () => _openMapPicker(false),
                  icon: const Icon(Icons.map_rounded, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Select on Map',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _customerAddressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Flat/House No, Landmark, Road, Pincode',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                  tooltip: 'Pick on Map',
                  onPressed: () => _openMapPicker(false),
                ),
              ),
              validator: (String? val) {
                if (val == null || val.trim().isEmpty) return 'Please provide your address.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Preferred Language Dropdown
            const Text(
              'Preferred Language',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _preferredLanguage,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.translate_rounded),
                labelText: 'App Language',
              ),
              items: _languages.map((String lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (String? val) {
                if (val != null) setState(() => _preferredLanguage = val);
              },
            ),
            const SizedBox(height: 32),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _handleNextFromForm,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Continue to Review', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 2 (WORKER): WORKER ONBOARDING (Page 3)
  // Name, Photo, Phone/email, Skills/trade, Experience, Working areas (map),
  // Availability, UPI/payment details, Document upload, Submit for verification
  // =========================================================================
  Widget _buildWorkerOnboardingStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 20),
      child: Form(
        key: _workerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Worker Partner Setup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete your trade credentials & payment details to receive cooperative jobs.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Profile photo picker with automatic JPG conversion & default avatar fallback
            ProfilePhotoPicker(
              fallbackName: _fullNameController.text,
              initialImageBytes: _profilePhotoJpgBytes,
              isWorker: true,
              onPhotoChanged: (Uint8List? bytes, String? base64) {
                _profilePhotoJpgBytes = bytes;
              },
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Legal Name (as per ID) *',
                hintText: 'e.g. Ramesh Kumar',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (String? val) {
                if (val == null || val.trim().isEmpty) return 'Full legal name is required.';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Phone
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Phone Number *',
                hintText: '98765 43210',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        '+91',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(height: 20, width: 1, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                ),
              ),
              validator: (String? val) {
                if (val == null || val.trim().isEmpty) return 'Please enter phone number.';
                final String digits = val.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) return 'Phone number must have 10 digits.';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Primary Trade / Skill Category
            DropdownButtonFormField<String>(
              initialValue: _workerTrade,
              decoration: const InputDecoration(
                labelText: 'Primary Trade Category *',
                prefixIcon: Icon(Icons.handyman_outlined),
              ),
              items: _tradeOptions.map((String trade) {
                return DropdownMenuItem<String>(value: trade, child: Text(trade));
              }).toList(),
              onChanged: (String? val) {
                if (val != null) setState(() => _workerTrade = val);
              },
            ),
            const SizedBox(height: 14),

            // Experience in Years
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Experience in Trade:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _experienceYears > 1 ? () => setState(() => _experienceYears--) : null,
                ),
                Text(
                  '$_experienceYears Years',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _experienceYears++),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Preferred Working Areas with Map Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Preferred Working Area / Location *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                TextButton.icon(
                  onPressed: () => _openMapPicker(true),
                  icon: const Icon(Icons.map_rounded, size: 16, color: AppColors.roleWorker),
                  label: const Text(
                    'Select on Map',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.roleWorker),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _workerPreferredAreasController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Kothrud, Shivaji Nagar, Deccan (Pune)',
                prefixIcon: const Icon(Icons.explore_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.pin_drop_rounded, color: AppColors.roleWorker),
                  onPressed: () => _openMapPicker(true),
                ),
              ),
              validator: (String? val) {
                if (val == null || val.trim().isEmpty) return 'Please specify preferred areas.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Availability Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Initial Availability Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      Text('Can be toggled anytime in dashboard', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Switch.adaptive(
                    value: _workerAvailableNow,
                    activeTrackColor: AppColors.success,
                    activeThumbColor: Colors.white,
                    onChanged: (bool val) => setState(() => _workerAvailableNow = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // UPI / Payout Details
            TextFormField(
              controller: _workerUpiController,
              decoration: const InputDecoration(
                labelText: 'UPI ID / Bank Payout Account *',
                hintText: 'mobile@upi or bank details',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              validator: (String? val) {
                if (val == null || val.trim().isEmpty) return 'UPI or payout account is required.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Document & Certificate Upload Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.roleWorker.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.roleWorker.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.file_present_rounded, color: AppColors.roleWorker, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Verification Document (ID/Certificate)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          _hasUploadedDoc ? _uploadedDocName : 'No file attached',
                          style: TextStyle(
                            fontSize: 11,
                            color: _hasUploadedDoc ? AppColors.success : Colors.grey,
                            fontWeight: _hasUploadedDoc ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _hasUploadedDoc = true;
                        _uploadedDocName = 'trade_license_certificate.jpg';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification document attached as JPG.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.roleWorker,
                      side: const BorderSide(color: AppColors.roleWorker),
                    ),
                    child: Text(_hasUploadedDoc ? 'Replace' : 'Upload'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit for Verification Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _handleNextFromForm,
                style: FilledButton.styleFrom(backgroundColor: AppColors.roleWorker),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Review & Submit for Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 3: REVIEW & CONFIRM
  // =========================================================================
  Widget _buildReviewAndSubmitStep(BuildContext context, bool isLoading) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String formattedPhone = _phoneNumberController.text.trim().isNotEmpty
        ? '+91 ${_phoneNumberController.text.trim()}'
        : 'Not provided';

    final Color roleColor = _selectedRole == UserRole.worker ? AppColors.roleWorker : AppColors.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Review & Confirm Profile',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verify all onboarding information before finalizing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: <Widget>[
                // Profile Avatar Row
                Row(
                  children: <Widget>[
                    ClipOval(
                      child: _profilePhotoJpgBytes != null
                          ? Image.memory(_profilePhotoJpgBytes!, width: 50, height: 50, fit: BoxFit.cover)
                          : Container(
                              width: 50,
                              height: 50,
                              color: roleColor.withValues(alpha: 0.15),
                              child: Center(
                                child: Text(
                                  _fullNameController.text.isNotEmpty
                                      ? _fullNameController.text[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: roleColor),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _fullNameController.text.trim().isNotEmpty
                                ? _fullNameController.text.trim()
                                : 'Not specified',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            _profilePhotoJpgBytes != null ? 'Custom JPG Photo' : 'Default Avatar',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _goToStep(1),
                    ),
                  ],
                ),
                const Divider(height: 24),


                _buildSummaryRow(
                  label: 'Phone Contact',
                  value: formattedPhone,
                  icon: Icons.phone_outlined,
                  onEdit: () => _goToStep(1),
                ),
                const Divider(height: 20),

                if (_selectedRole == UserRole.customer) ...<Widget>[
                  _buildSummaryRow(
                    label: 'Service Address (Map Selected)',
                    value: _customerAddressController.text.trim(),
                    icon: Icons.location_on_outlined,
                    onEdit: () => _goToStep(1),
                  ),
                  if (_customerHouseFlat.isNotEmpty || _customerBuilding.isNotEmpty) ...<Widget>[
                    const Divider(height: 20),
                    _buildSummaryRow(
                      label: 'Doorstep Details',
                      value: '${_customerHouseFlat.isNotEmpty ? _customerHouseFlat : ""}${_customerBuilding.isNotEmpty ? " • $_customerBuilding" : ""}${_customerLandmark.isNotEmpty ? " (Near $_customerLandmark)" : ""}',
                      icon: Icons.door_front_door_outlined,
                      onEdit: () => _goToStep(1),
                    ),
                  ],
                  const Divider(height: 20),
                  _buildSummaryRow(
                    label: 'Preferred Language',
                    value: _preferredLanguage,
                    icon: Icons.translate_rounded,
                    onEdit: () => _goToStep(1),
                  ),
                ] else ...<Widget>[
                  _buildSummaryRow(
                    label: 'Trade Category & Experience',
                    value: '$_workerTrade • $_experienceYears Years',
                    icon: Icons.handyman_outlined,
                    onEdit: () => _goToStep(1),
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    label: 'Preferred Working Area',
                    value: _workerPreferredAreasController.text.trim(),
                    icon: Icons.map_outlined,
                    onEdit: () => _goToStep(1),
                  ),
                  if (_customerHouseFlat.isNotEmpty || _customerBuilding.isNotEmpty) ...<Widget>[
                    const Divider(height: 20),
                    _buildSummaryRow(
                      label: 'Base Address Details',
                      value: '${_customerHouseFlat.isNotEmpty ? _customerHouseFlat : ""}${_customerBuilding.isNotEmpty ? " • $_customerBuilding" : ""}',
                      icon: Icons.door_front_door_outlined,
                      onEdit: () => _goToStep(1),
                    ),
                  ],
                  const Divider(height: 20),
                  _buildSummaryRow(
                    label: 'Payout UPI',
                    value: _workerUpiController.text.trim(),
                    icon: Icons.account_balance_wallet_outlined,
                    onEdit: () => _goToStep(1),
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    label: 'Attached Document',
                    value: _uploadedDocName,
                    icon: Icons.verified_outlined,
                    accentColor: AppColors.success,
                    onEdit: () => _goToStep(1),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Privacy & Verification Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.lock_outline, size: 16, color: roleColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All details verified. Your account and profile will be created in the database upon clicking complete.',
                    style: TextStyle(fontSize: 11.5, color: roleColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Submit Action
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : _handleFinishOnboarding,
              style: FilledButton.styleFrom(backgroundColor: roleColor),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _selectedRole == UserRole.worker
                              ? 'Complete Worker Registration & Enter'
                              : 'Complete Registration & Enter App',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_outline, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
    Color? accentColor,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: accentColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: accentColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 16),
          tooltip: 'Edit',
          onPressed: onEdit,
        ),
      ],
    );
  }
}

class _SimpleRoleCard extends StatelessWidget {
  const _SimpleRoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor = isSelected
        ? accentColor
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.12 : 0.04)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: accentColor),
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
                      color: isSelected
                          ? (isDark ? Colors.white : accentColor)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected
                    ? accentColor
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
