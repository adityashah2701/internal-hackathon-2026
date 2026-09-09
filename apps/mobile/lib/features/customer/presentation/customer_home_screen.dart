import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_role.dart';
import '../../common/role_placeholder_scaffold.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderScaffold(
      title: 'Customer Home',
      role: UserRole.customer,
      roleColor: AppColors.roleCustomer,
      roleIcon: Icons.person_pin_circle_outlined,
      description: 'You are authenticated as a Customer.\n\nNext capabilities will include:\n• Cooperative service catalog & discovery\n• GPS-based nearest worker matching\n• OTP verified service completion\n• Transparent invoicing & review rating',
    );
  }
}
