import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/locale_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/user_role.dart';
import '../auth/controllers/auth_controller.dart';

class RolePlaceholderScaffold extends ConsumerWidget {
  const RolePlaceholderScaffold({
    super.key,
    required this.title,
    required this.role,
    required this.roleColor,
    required this.roleIcon,
    required this.description,
  });

  final String title;
  final UserRole role;
  final Color roleColor;
  final IconData roleIcon;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppAuthState? authState = ref.watch(authControllerProvider).value;
    final UserProfile? profile = authState is AuthAuthenticated ? authState.profile : null;
    final Locale currentLocale = ref.watch(localeProvider);
    final ThemeMode currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: <Widget>[
          // Language selector
          PopupMenuButton<Locale>(
            tooltip: 'Languages',
            initialValue: currentLocale,
            icon: const Icon(Icons.language),
            onSelected: (Locale locale) {
              ref.read<LocaleNotifier>(localeProvider.notifier).setLocale(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              const PopupMenuItem<Locale>(
                value: Locale('en'),
                child: Text('English (EN)'),
              ),
              const PopupMenuItem<Locale>(
                value: Locale('hi'),
                child: Text('हिन्दी (HI)'),
              ),
              const PopupMenuItem<Locale>(
                value: Locale('mr'),
                child: Text('मराठी (MR)'),
              ),
            ],
          ),
          // Theme mode toggle
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              currentThemeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read<ThemeModeNotifier>(themeModeProvider.notifier).toggleTheme();
            },
          ),
          // Logout button
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // User Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      child: Icon(roleIcon, size: 40, color: roleColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Active User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        role.displayName.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Feature Roadmap Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.construction_outlined, color: roleColor, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Module Architecture Ready',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Button to jump to system verification / diagnostics
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.verification),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Open System Diagnostics'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Sign Out button
            FilledButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
