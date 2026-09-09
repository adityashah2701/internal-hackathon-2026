import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerProfileTab extends ConsumerWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          child: const Text('Sign Out'),
        ),
      ),
    );
  }
}
