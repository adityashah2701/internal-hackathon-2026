import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/worker_controller.dart';

/// Page 15 — Worker Profile, Guild Certifications & Availability Hub
/// Features craftsperson portfolio, working radius slider, shift management,
/// trade skills editor, verified documents list, and banking configuration.
class WorkerProfileTab extends ConsumerStatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  ConsumerState<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends ConsumerState<WorkerProfileTab> {
  bool _isAvailable = true;
  double _workingRadiusKm = 12.0;
  bool _morningShift = true;
  bool _afternoonShift = true;
  bool _emergencyOnDemand = true;

  final List<String> _skills = <String>[
    'Domestic Electrical Wiring',
    'MCB Breaker & Short Circuit Repair',
    'Inverter & UPS Setup',
    'Appliance Earthing & Surge Protection',
    'Sub-meter Installation',
  ];

  void _openAddSkillModal() {
    final TextEditingController controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Add Trade Skill'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. 3-Phase Industrial Panel Wiring',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String text = controller.text.trim();
                if (text.isNotEmpty) {
                  setState(() => _skills.add(text));
                }
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('Add Skill'),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of your worker workspace?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final WorkerDashboardState state = ref.watch(workerDashboardProvider);
    final String workerName = (state.profile.fullName != null && state.profile.fullName!.isNotEmpty)
        ? state.profile.fullName!
        : 'Ramesh Sharma';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Craftsman Portfolio', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(workerDashboardProvider.notifier).loadDashboard();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Profile & Guild Identity Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Stack(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            child: const Text(
                              'RS',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  workerName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Level 4 Master Artisan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pune Electrical Workers Coop #4182',
                              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Rating, Reviews & Completed stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _buildStatColumn('Rating', '★ 4.9', Colors.amber),
                      _buildStatColumn('Reviews', '148', null),
                      _buildStatColumn('Experience', '9 Yrs', null),
                      _buildStatColumn('Welfare Tier', 'Gold', AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Availability & Coverage Section
            _buildSectionHeader('Availability & Service Radius'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Online / Duty Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isAvailable ? AppColors.success : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAvailable ? 'Ready for Dispatch (Online)' : 'Off Duty (Offline)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isAvailable,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: AppColors.onPrimary,
                        onChanged: (bool val) => setState(() => _isAvailable = val),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Radius Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Coverage Area Radius',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_workingRadiusKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _workingRadiusKm,
                    min: 3.0,
                    max: 25.0,
                    divisions: 22,
                    activeColor: AppColors.primary,
                    label: '${_workingRadiusKm.toStringAsFixed(0)} km',
                    onChanged: (double val) => setState(() => _workingRadiusKm = val),
                  ),
                  Text(
                    'Covers Kothrud, Deccan, Shivajinagar, Karve Nagar, and Warje nodes.',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  const Divider(height: 20),

                  // Shifts
                  const Text('Active Shift Preferences', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilterChip(
                        label: const Text('Morning (8 AM - 2 PM)'),
                        selected: _morningShift,
                        onSelected: (bool val) => setState(() => _morningShift = val),
                      ),
                      FilterChip(
                        label: const Text('Afternoon (2 PM - 8 PM)'),
                        selected: _afternoonShift,
                        onSelected: (bool val) => setState(() => _afternoonShift = val),
                      ),
                      FilterChip(
                        label: const Text('Emergency On-Call (+₹100)'),
                        selected: _emergencyOnDemand,
                        onSelected: (bool val) => setState(() => _emergencyOnDemand = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trade Skills Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildSectionHeader('Certified Trade Skills (${_skills.length})'),
                TextButton.icon(
                  onPressed: _openAddSkillModal,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Skill', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((String skill) {
                return Chip(
                  avatar: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  label: Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF3F4F6),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Banking & Settlement Info Card
            _buildSectionHeader('Direct Settlement Details'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: <Widget>[
                  _buildBankDetailRow('UPI ID', 'ramesh.sharma@okhdfcbank', Icons.bolt_rounded, isVerified: true),
                  const Divider(height: 18),
                  _buildBankDetailRow('Settlement Bank', 'HDFC Bank (Kothrud Branch)', Icons.account_balance_rounded),
                  const Divider(height: 18),
                  _buildBankDetailRow('Account Number', '•••• •••• 8492', Icons.credit_card_rounded),
                  const Divider(height: 18),
                  _buildBankDetailRow('IFSC Code', 'HDFC0001092', Icons.numbers_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cooperative Credentials & Verification Badges
            _buildSectionHeader('Cooperative Credentials & Welfare Status'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: <Widget>[
                  _buildCredentialRow(
                    title: 'Aadhaar Identity Verification',
                    status: 'Federation Verified',
                    statusColor: AppColors.success,
                    icon: Icons.badge_rounded,
                  ),
                  const Divider(height: 18),
                  _buildCredentialRow(
                    title: 'ITI Electrician Trade Certificate',
                    status: 'Guild Approved',
                    statusColor: AppColors.success,
                    icon: Icons.school_rounded,
                  ),
                  const Divider(height: 18),
                  _buildCredentialRow(
                    title: 'District Cooperative Membership',
                    status: 'Active Member #4182',
                    statusColor: AppColors.primary,
                    icon: Icons.groups_rounded,
                  ),
                  const Divider(height: 18),
                  _buildCredentialRow(
                    title: 'State Labour Board Accident Policy',
                    status: '₹5,00,000 Cover Active',
                    statusColor: AppColors.success,
                    icon: Icons.health_and_safety_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out from Craftsman Account', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildStatColumn(String label, String value, Color? color) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBankDetailRow(String label, String value, IconData icon, {bool isVerified = false}) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success)),
          ),
      ],
    );
  }

  Widget _buildCredentialRow({
    required String title,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: statusColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
          ),
        ),
      ],
    );
  }
}
