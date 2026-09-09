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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  final TextEditingController _phoneNumberController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;

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
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _handleCompleteOnboarding() {
    if (!_formKey.currentState!.validate()) return;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Welcome Header
              Text(
                'Welcome to Sahayog',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please set up your profile and choose your primary role to proceed into the cooperative marketplace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 24),

              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full legal name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'e.g. 9876543210',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 28),

              // Role Selection Header
              Text(
                'Choose Your Role *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Customer Role Option
              _RoleSelectionCard(
                title: 'Customer (Household / Client)',
                description: 'Search, book, and review certified cooperative services at fair transparent rates.',
                icon: Icons.person_pin_circle_outlined,
                accentColor: AppColors.roleCustomer,
                isSelected: _selectedRole == UserRole.customer,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.customer;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Worker Role Option
              _RoleSelectionCard(
                title: 'Worker / Service Provider',
                description: 'Get nearby service job alerts, transparent digital earnings, and cooperative welfare coverage.',
                icon: Icons.engineering_outlined,
                accentColor: AppColors.roleWorker,
                isSelected: _selectedRole == UserRole.worker,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.worker;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Security Notice for Admins
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.shield_outlined, size: 20, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Administrative roles (Cooperative & Federation Admins) cannot be self-selected. They are verified and provisioned by cooperative apex executives.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              FilledButton(
                onPressed: isLoading ? null : _handleCompleteOnboarding,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Complete Setup & Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  const _RoleSelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected ? accentColor : Theme.of(context).dividerColor.withValues(alpha: 0.3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.08) : Theme.of(context).cardColor,
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 28, color: isSelected ? accentColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? accentColor : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 2.0),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? accentColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
