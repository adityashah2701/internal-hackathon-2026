import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/cooperative_society.dart';
import '../../../data/models/worker_profile.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/federation_admin_controller.dart';

class FederationHomeScreen extends ConsumerStatefulWidget {
  const FederationHomeScreen({super.key});

  @override
  ConsumerState<FederationHomeScreen> createState() => _FederationHomeScreenState();
}

class _FederationHomeScreenState extends ConsumerState<FederationHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FederationAdminState state = ref.watch(federationAdminProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Federation Apex Oversight',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            Text(
              'State / Apex Governance Portal',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => ref.read(federationAdminProvider.notifier).loadDashboard(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(federationAdminProvider.notifier).loadDashboard();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // 1. Executive Telemetry KPI Cards
                    _buildKpiMetricsGrid(context, state, isDark),
                    const SizedBox(height: 24),

                    // 2. Active Cooperatives Section
                    _buildCooperativesSection(context, state.cooperatives, isDark),
                    const SizedBox(height: 24),

                    // 3. Demand Forecasting
                    _buildDemandForecastEmptyState(context, isDark),
                    const SizedBox(height: 24),

                    // 4. Workforce Directory & Search / Filter
                    _buildWorkforceDirectorySection(context, state, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiMetricsGrid(BuildContext context, FederationAdminState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'STATE WORKFORCE TELEMETRY',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildMetricCard(
                title: 'Total Workforce',
                value: '${state.metrics.totalWorkers}',
                icon: Icons.people_outline_rounded,
                iconColor: AppColors.roleWorker,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Certified Active',
                value: '${state.metrics.verifiedWorkers}',
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.success,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildMetricCard(
                title: 'Pending Approvals',
                value: '${state.metrics.pendingVerifications}',
                icon: Icons.pending_actions_outlined,
                iconColor: Colors.orange,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Primary Societies',
                value: '${state.metrics.activeCooperatives}',
                icon: Icons.account_balance_outlined,
                iconColor: AppColors.roleFederation,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemandForecastEmptyState(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'PREDICTIVE DEMAND FORECASTING',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2), style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.auto_graph_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Insufficient Data for AI Forecasting',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'The predictive models require at least 30 days of historical booking data across multiple sectors to generate accurate workforce demand projections.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: 0.15,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              const Text(
                'Data Collection Progress: 15%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildCooperativesSection(
      BuildContext context, List<CooperativeSociety> societies, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              'Affiliated Primary Societies',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              '${societies.length} Registered',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        ),
        if (societies.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.account_balance_outlined, color: Colors.grey.shade400, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No primary societies registered yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: societies.length,
              separatorBuilder: (BuildContext context, int i) => const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int index) {
                final CooperativeSociety society = societies[index];
                return Container(
                  width: 240,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        society.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${society.district}, ${society.state}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.roleCooperative.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          society.code,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.roleCooperative,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWorkforceDirectorySection(
      BuildContext context, FederationAdminState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Workforce Registry & Certification',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),

        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by worker name, trade skill, or locality...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(federationAdminProvider.notifier).setSearchQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          onChanged: (String val) {
            ref.read(federationAdminProvider.notifier).setSearchQuery(val);
          },
        ),

        const SizedBox(height: 12),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _buildFilterChip('all', 'All Workers', state.statusFilter),
              const SizedBox(width: 8),
              _buildFilterChip('approved', 'Verified Only', state.statusFilter),
              const SizedBox(width: 8),
              _buildFilterChip('pending', 'Pending Approval', state.statusFilter),
              const SizedBox(width: 8),
              _buildFilterChip('rejected', 'Rejected / Re-apply', state.statusFilter),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Worker roster list
        if (state.workers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.person_search_outlined,
                  size: 48,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No Workers Found',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try refining your trade search or filter criteria.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.workers.length,
            separatorBuilder: (BuildContext context, int i) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final WorkerProfile worker = state.workers[index];
              return _buildWorkerRosterItem(context, worker, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, String activeFilter) {
    final bool isSelected = activeFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          ref.read(federationAdminProvider.notifier).setStatusFilter(key);
        }
      },
    );
  }

  Widget _buildWorkerRosterItem(BuildContext context, WorkerProfile worker, bool isDark) {
    final (Color badgeBg, Color badgeColor, String statusText) = switch (worker.verificationStatus) {
      WorkerVerificationStatus.approved => (
          AppColors.success.withAlpha(20),
          AppColors.success,
          'CERTIFIED'
        ),
      WorkerVerificationStatus.pending => (
          Colors.orange.withAlpha(20),
          Colors.orange.shade800,
          'PENDING'
        ),
      WorkerVerificationStatus.rejected => (
          AppColors.error.withAlpha(20),
          AppColors.error,
          'REJECTED'
        ),
      WorkerVerificationStatus.unsubmitted => (
          Colors.grey.withAlpha(20),
          Colors.grey,
          'UNSUBMITTED'
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.roleWorker.withAlpha(20),
            child: Text(
              worker.displayName.isNotEmpty ? worker.displayName[0].toUpperCase() : 'W',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.roleWorker, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      worker.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${worker.skills.isNotEmpty ? worker.skills.join(", ") : "General Worker"} • ${worker.experienceYears} yrs',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  worker.cooperativeName ?? 'Shramik Kalyan Labour Cooperative Society',
                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            '₹${worker.dailyRateInr}/day',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of the Federation Portal?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                ref.read(authControllerProvider.notifier).signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
