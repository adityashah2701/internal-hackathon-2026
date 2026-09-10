import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_profile.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../common/presentation/help_support_screen.dart';
import '../../../common/presentation/widgets/safety_sos_modal.dart';
import '../../controllers/customer_booking_controller.dart';

class CustomerProfileTab extends ConsumerStatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  ConsumerState<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends ConsumerState<CustomerProfileTab> {
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _savedAddresses = <Map<String, String>>[
    {
      'label': 'Home',
      'address': 'Flat 301, Marvel Residency, Kothrud, Pune - 411038',
      'isDefault': 'true',
    },
    {
      'label': 'Office',
      'address': 'Level 4, Synergy IT Park, Phase 1, Hinjewadi, Pune - 411057',
      'isDefault': 'false',
    },
  ];

  void _openAddAddressSheet(BuildContext context) {
    final TextEditingController labelCtrl = TextEditingController(text: 'Other');
    final TextEditingController addrCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Add Saved Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Address Label (e.g. Home, Parents, Studio)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Complete Street Address & Pincode'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (addrCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      _savedAddresses.add(<String, String>{
                        'label': labelCtrl.text.trim(),
                        'address': addrCtrl.text.trim(),
                        'isDefault': 'false',
                      });
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address added successfully!')),
                    );
                  }
                },
                child: const Text('Save Address'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of Sahayog?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.of(ctx).pop();
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
    final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
    final CustomerDashboardState state = ref.watch(customerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final UserProfile? profile = authAsync.value is AuthAuthenticated
        ? (authAsync.value as AuthAuthenticated).profile
        : null;

    final String displayName = profile?.fullName ?? 'Cooperative Customer';
    final String displayPhone = profile?.phoneNumber.isNotEmpty == true
        ? '+91 ${profile!.phoneNumber}'
        : '+91 98765 43210';
    final String displayEmail = profile?.email ?? 'customer@sahayog.coop';

    // Calculate community welfare impact
    final int completedCount = state.bookings.where((b) => b.status.displayName == 'Completed' || b.status.displayName == 'Reviewed').length;
    final int totalWelfareContributed = state.bookings
        .where((b) => b.status.displayName == 'Completed' || b.status.displayName == 'Reviewed')
        .fold(0, (int sum, b) => sum + b.welfareFee);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // User Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayPhone,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayEmail,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Collective Welfare Impact Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? <Color>[const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : <Color>[const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Your Collective Community Impact',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.primaryLight : const Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          '$completedCount',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('Jobs Empowered', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Container(height: 32, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                    Column(
                      children: <Widget>[
                        Text(
                          '₹$totalWelfareContributed',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success),
                        ),
                        const SizedBox(height: 2),
                        const Text('Worker Welfare Pool', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Saved Addresses Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Saved Addresses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add New'),
                onPressed: () => _openAddAddressSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._savedAddresses.map((Map<String, String> addr) {
            final bool isDef = addr['isDefault'] == 'true';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: ListTile(
                leading: Icon(
                  addr['label'] == 'Home'
                      ? Icons.home_rounded
                      : (addr['label'] == 'Office' ? Icons.business_rounded : Icons.location_on_rounded),
                  color: AppColors.primary,
                ),
                title: Row(
                  children: <Widget>[
                    Text(addr['label']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    if (isDef) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  addr['address']!,
                  style: const TextStyle(fontSize: 11.5, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Language Preferences
          const Text('Preferred Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: <Widget>[
                RadioListTile<String>(
                  title: const Text('English (Default)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  value: 'en',
                  groupValue: _selectedLanguage,
                  activeColor: AppColors.primary,
                  onChanged: (String? val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('हिन्दी (Hindi)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  value: 'hi',
                  groupValue: _selectedLanguage,
                  activeColor: AppColors.primary,
                  onChanged: (String? val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('मराठी (Marathi)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  value: 'mr',
                  groupValue: _selectedLanguage,
                  activeColor: AppColors.primary,
                  onChanged: (String? val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cooperative Safety, Help & Legal
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.sos_rounded, color: AppColors.error),
                  title: const Text('Safety & Emergency SOS Center', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext ctx) => const SafetySosModal(),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
                  title: const Text('FAQ, Help & Dispute Resolution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext ctx) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Sign out button
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out of Sahayog'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _confirmSignOut(context),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '${AppConstants.appName} v1.0 • Maharashtra Cooperative Federation',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
