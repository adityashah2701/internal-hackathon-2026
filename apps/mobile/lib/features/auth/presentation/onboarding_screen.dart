import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_role.dart';
import '../controllers/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _detailsFormKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  final TextEditingController _phoneNumberController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  int _currentStep = 0;
  static const int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    final AppAuthState? authState = ref.read(authControllerProvider).value;
    String initialName = '';
    if (authState is AuthOnboardingRequired && authState.profile != null) {
      initialName = authState.profile!.fullName;
    }
    _fullNameController = TextEditingController(text: initialName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
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

  void _handleNextFromDetails() {
    if (!_detailsFormKey.currentState!.validate()) return;
    _goToStep(2);
  }

  void _handleFinishOnboarding() {
    ref.read(authControllerProvider.notifier).completeOnboarding(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppAuthState> authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.isLoading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<AppAuthState>>(authControllerProvider, (AsyncValue<AppAuthState>? prev, AsyncValue<AppAuthState> next) {
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
          'Step ${_currentStep + 1} of $_totalSteps',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: isLoading ? null : () => ref.read(authControllerProvider.notifier).signOut(),
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
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          // Multi-step PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _buildWelcomeStep(context),
                _buildDetailsStep(context),
                _buildRoleStep(context),
                _buildReviewStep(context, isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 1: WELCOME
  // ==========================================
  Widget _buildWelcomeStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Spacer(),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.handshake_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Welcome to Sahayog',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'A transparent digital platform connecting communities with verified cooperative service workers.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ),
          const SizedBox(height: 32),

          // Quick Highlights
          _buildPerkRow(Icons.groups_outlined, 'Owned & governed by cooperative labor societies'),
          const SizedBox(height: 12),
          _buildPerkRow(Icons.verified_outlined, 'Transparent rates with guaranteed worker welfare'),
          const SizedBox(height: 12),
          _buildPerkRow(Icons.lock_outline, 'Secure identity verification and escrow protection'),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => _goToStep(1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildPerkRow(IconData icon, String text) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: BASIC PROFILE (DETAILS)
  // ==========================================
  Widget _buildDetailsStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 24),
      child: Form(
        key: _detailsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Your Details',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your contact details so we can verify your identity.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 28),

            // Full Name Input
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g. Ramesh Kumar',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full legal name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number Input with +91 badge
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
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
                      Container(
                        height: 20,
                        width: 1,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your mobile phone number.';
                }
                final String digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) {
                  return 'Phone number must have at least 10 digits.';
                }
                return null;
              },
            ),
            const SizedBox(height: 36),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _handleNextFromDetails,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  // ==========================================
  // STEP 3: ROLE SELECTION
  // ==========================================
  Widget _buildRoleStep(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Select Your Role',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you plan to use Sahayog.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Customer Option Card
          _SimpleRoleCard(
            title: 'Customer',
            subtitle: 'I want to hire & book cooperative services',
            icon: Icons.shopping_bag_outlined,
            accentColor: AppColors.roleCustomer,
            isSelected: _selectedRole == UserRole.customer,
            onTap: () {
              setState(() {
                _selectedRole = UserRole.customer;
              });
            },
          ),
          const SizedBox(height: 12),

          // Worker Option Card
          _SimpleRoleCard(
            title: 'Worker / Service Partner',
            subtitle: 'I want to offer services & earn with cooperative welfare',
            icon: Icons.engineering_outlined,
            accentColor: AppColors.roleWorker,
            isSelected: _selectedRole == UserRole.worker,
            onTap: () {
              setState(() {
                _selectedRole = UserRole.worker;
              });
            },
          ),
          const SizedBox(height: 24),

          // Admin Callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.shield_outlined, size: 18, color: AppColors.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cooperative Admin roles are assigned by apex executives under cooperative bylaws.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => _goToStep(3),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  // ==========================================
  // STEP 4: REVIEW & COMPLETE
  // ==========================================
  Widget _buildReviewStep(BuildContext context, bool isLoading) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String formattedPhone = _phoneNumberController.text.trim().isNotEmpty
        ? '+91 ${_phoneNumberController.text.trim()}'
        : 'Not provided';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Review & Confirm',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confirm your details before entering your dashboard.',
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
                _buildSummaryRow(
                  label: 'Full Name',
                  value: _fullNameController.text.trim().isNotEmpty
                      ? _fullNameController.text.trim()
                      : 'Not provided',
                  icon: Icons.person_outline,
                  onEdit: () => _goToStep(1),
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  label: 'Mobile Number',
                  value: formattedPhone,
                  icon: Icons.phone_outlined,
                  onEdit: () => _goToStep(1),
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  label: 'Marketplace Role',
                  value: _selectedRole.displayName,
                  icon: _selectedRole == UserRole.worker ? Icons.engineering_outlined : Icons.shopping_bag_outlined,
                  accentColor: _selectedRole == UserRole.worker ? AppColors.roleWorker : AppColors.roleCustomer,
                  onEdit: () => _goToStep(2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security Trust note
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Protected by Cooperative Data Governance Standards',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Submit Action
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: isLoading ? null : _handleFinishOnboarding,
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Confirm & Enter Dashboard',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle_outline, size: 18),
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
                  fontSize: 14.5,
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
            width: isSelected ? 1.6 : 1.0,
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
