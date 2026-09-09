import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../providers/verification_provider.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final DiagnosticsState diagnostics = ref.watch(diagnosticsProvider);
    final Locale currentLocale = ref.watch(localeProvider);
    final ThemeMode currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.systemVerification ?? 'System Diagnostics',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: <Widget>[
          // Language selector (en, hi, mr)
          PopupMenuButton<Locale>(
            tooltip: l10n?.supportedLanguages ?? 'Languages',
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
              currentThemeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read<ThemeModeNotifier>(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read<DiagnosticsNotifier>(diagnosticsProvider.notifier).checkConnectivity();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.handshake_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n?.appName ?? AppConstants.appName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n?.appTagline ?? AppConstants.appTagline,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Diagnostics Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Foundation Readiness',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 24),
                      _DiagnosticRow(
                        label: l10n?.appVersion ?? 'App Version',
                        value: diagnostics.appVersion,
                        icon: Icons.tag,
                      ),
                      const SizedBox(height: 12),
                      _DiagnosticRow(
                        label: l10n?.environment ?? 'Environment',
                        value: diagnostics.environment.toUpperCase(),
                        icon: Icons.tune,
                      ),
                      const SizedBox(height: 12),
                      _DiagnosticRow(
                        label: l10n?.supabaseStatus ?? 'Supabase Host',
                        value: diagnostics.sanitizedHost,
                        icon: Icons.cloud_queue,
                      ),
                      const SizedBox(height: 12),
                      _DiagnosticRowWithChip(
                        label: 'Client Config',
                        icon: Icons.check_circle_outline,
                        chipLabel: diagnostics.isConfigured
                            ? (l10n?.statusConfigured ?? 'Configured')
                            : (l10n?.statusNotConfigured ?? 'Pending Config'),
                        chipColor: diagnostics.isConfigured
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(height: 12),
                      _DiagnosticRowWithChip(
                        label: 'Connectivity',
                        icon: Icons.network_ping,
                        chipLabel: switch (diagnostics.connectivityStatus) {
                          SupabaseConnectivityStatus.connected => 'Connected',
                          SupabaseConnectivityStatus.connecting => 'Connecting...',
                          SupabaseConnectivityStatus.unreachable => 'Unreachable',
                          SupabaseConnectivityStatus.notConfigured => 'Offline',
                        },
                        chipColor: switch (diagnostics.connectivityStatus) {
                          SupabaseConnectivityStatus.connected => AppColors.success,
                          SupabaseConnectivityStatus.connecting => AppColors.info,
                          SupabaseConnectivityStatus.unreachable => AppColors.error,
                          SupabaseConnectivityStatus.notConfigured => AppColors.textSecondaryLight,
                        },
                      ),
                      const SizedBox(height: 12),
                      _DiagnosticRow(
                        label: l10n?.authSession ?? 'Auth Session',
                        value: diagnostics.hasActiveAuthSession
                            ? 'Authenticated Session'
                            : (l10n?.noActiveSession ?? 'No Active Session (Guest)'),
                        icon: Icons.lock_outline,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Future Role Architecture Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Target Role Architecture (PS-089)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _RoleChip(
                            label: l10n?.roleCustomer ?? 'Customer',
                            color: AppColors.roleCustomer,
                            icon: Icons.person_outline,
                          ),
                          _RoleChip(
                            label: l10n?.roleWorker ?? 'Worker',
                            color: AppColors.roleWorker,
                            icon: Icons.engineering_outlined,
                          ),
                          _RoleChip(
                            label: l10n?.roleCooperativeAdmin ?? 'Cooperative Admin',
                            color: AppColors.roleCooperative,
                            icon: Icons.groups_outlined,
                          ),
                          _RoleChip(
                            label: l10n?.roleFederationAdmin ?? 'Federation Admin',
                            color: AppColors.roleFederation,
                            icon: Icons.account_balance_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Re-check button
              FilledButton.icon(
                onPressed: () {
                  ref.read<DiagnosticsNotifier>(diagnosticsProvider.notifier).checkConnectivity();
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  l10n?.refreshDiagnostics ?? 'Re-check Diagnostics',
                ),
              ),

              const SizedBox(height: 16),

              // Security & Privacy Disclaimer
              Center(
                child: Text(
                  'Zero credentials displayed • Client-safe architecture\nAll database operations governed by PostgreSQL RLS',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
          ),
        ),
      ],
    );
  }
}

class _DiagnosticRowWithChip extends StatelessWidget {
  const _DiagnosticRowWithChip({
    required this.label,
    required this.icon,
    required this.chipLabel,
    required this.chipColor,
  });

  final String label;
  final IconData icon;
  final String chipLabel;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chipColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            chipLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
    );
  }
}
