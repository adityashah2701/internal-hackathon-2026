import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_role.dart';
import '../../common/role_placeholder_scaffold.dart';

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolePlaceholderScaffold(
      title: 'Worker Home',
      role: UserRole.worker,
      roleColor: AppColors.roleWorker,
      roleIcon: Icons.engineering_outlined,
      description: 'You are authenticated as a Cooperative Worker.\n\nNext capabilities will include:\n• Real-time local job dispatch radar\n• Customer OTP handshake verification\n• Direct earnings breakdown with 0% predatory commission\n• Society welfare & insurance ledger access',
    );
  }
}
