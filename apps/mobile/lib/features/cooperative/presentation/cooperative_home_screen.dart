import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_role.dart';
import '../../common/role_placeholder_scaffold.dart';

class CooperativeHomeScreen extends StatelessWidget {
  const CooperativeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderScaffold(
      title: 'Cooperative Admin',
      role: UserRole.cooperativeAdmin,
      roleColor: AppColors.roleCooperative,
      roleIcon: Icons.groups_outlined,
      description: 'You are authenticated as a Primary Society Manager.\n\nNext capabilities will include:\n• Worker KYC & skill certification approvals\n• Society member roster & active status monitor\n• Society welfare fund balance & dividend distribution\n• Regional booking oversight',
    );
  }
}
