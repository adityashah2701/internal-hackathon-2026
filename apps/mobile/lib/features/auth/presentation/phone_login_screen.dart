import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    
    final String phone = '+91${_phoneController.text.trim()}';
    
    ref.read(authControllerProvider.notifier).signInWithPhone(phone: phone);
    
    // Navigate to OTP verification screen, passing the phone number as state
    context.push(AppRoutes.otpVerify, extra: phone);
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
        title: const Text('Login with Phone'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Enter your mobile number',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will send you a 6-digit verification code.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 36),

                  // Phone Number Input with +91 badge
                  TextFormField(
                    controller: _phoneController,
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
                  const SizedBox(height: 24),

                  // Submit button
                  FilledButton(
                    onPressed: isLoading ? null : _handleSendOtp,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Verification Code', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
