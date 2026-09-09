import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/user_role.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/customer_booking_controller.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _resolveCategoryIcon(String iconName) {
    return switch (iconName) {
      'flash_on_rounded' => Icons.flash_on_rounded,
      'water_drop_rounded' => Icons.water_drop_rounded,
      'handyman_rounded' => Icons.handyman_rounded,
      'cleaning_services_rounded' => Icons.cleaning_services_rounded,
      'volunteer_activism_rounded' => Icons.volunteer_activism_rounded,
      'devices_other_rounded' => Icons.devices_other_rounded,
      'format_paint_rounded' => Icons.format_paint_rounded,
      _ => Icons.build_rounded,
    };
  }

  void _openBookingSheet(BuildContext context, ServiceCategoryItem category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        return _BookingWizardModal(category: category);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomerDashboardState state = ref.watch(customerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<CustomerDashboardState>(customerDashboardProvider, (CustomerDashboardState? prev, CustomerDashboardState next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Sahayog Services',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Row(
              children: <Widget>[
                Icon(Icons.location_on, size: 12, color: AppColors.primary),
                SizedBox(width: 3),
                Text(
                  'Pune Urban District • Cooperative Federation',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: 'Switch Portal / Role',
            icon: const Icon(Icons.swap_horiz_rounded),
            onSelected: (String route) {
              if (route == 'verification') {
                context.push(AppRoutes.verification);
              } else if (route == 'worker') {
                ref.read(authControllerProvider.notifier).setDemoUser(UserRole.worker);
                context.go(AppRoutes.workerDashboard);
              } else if (route == 'coop') {
                ref.read(authControllerProvider.notifier).setDemoUser(UserRole.cooperativeAdmin);
                context.go(AppRoutes.cooperativeDashboard);
              } else if (route == 'fed') {
                ref.read(authControllerProvider.notifier).setDemoUser(UserRole.federationAdmin);
                context.go(AppRoutes.federationDashboard);
              }
            },
            itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'verification',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text('Worker Verification Wizard'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'worker',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.engineering_outlined, color: AppColors.roleWorker, size: 20),
                    SizedBox(width: 10),
                    Text('Worker Workspace'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'coop',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.admin_panel_settings_outlined, color: AppColors.roleCooperative, size: 20),
                    SizedBox(width: 10),
                    Text('Cooperative Admin'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'fed',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.account_balance_outlined, color: AppColors.roleFederation, size: 20),
                    SizedBox(width: 10),
                    Text('Federation Admin'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(customerDashboardProvider.notifier).loadCustomerBookings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Cooperative Trust Banner with Hero Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/service_banner.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.black.withValues(alpha: 0.82),
                              Colors.black.withValues(alpha: 0.50),
                              Colors.black.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(Icons.handshake_rounded, color: Colors.amberAccent, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Direct Cooperative Guarantee',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Zero corporate commissions. Verified union professionals with state cooperative welfare board backing.',
                              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (String val) {
                  ref.read(customerDashboardProvider.notifier).setSearchQuery(val.trim());
                },
                decoration: InputDecoration(
                  hintText: 'Search trades (e.g. Electrician, Pipe leak, AC)...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(customerDashboardProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Service Categories Grid Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Cooperative Service Categories',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    '${state.filteredCategories.length} Available',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Categories Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: state.filteredCategories.length,
                itemBuilder: (BuildContext ctx, int index) {
                  final ServiceCategoryItem cat = state.filteredCategories[index];
                  return _buildCategoryCard(context, cat, isDark);
                },
              ),
              const SizedBox(height: 28),

              // Active & Recent Bookings Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Your Service Bookings',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    '${state.bookings.length} Total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bookings List
              if (state.bookings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(Icons.calendar_today_rounded, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      const Text(
                        'No service bookings yet',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select any trade category above to schedule your first service.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext ctx, int idx) {
                    final Booking b = state.bookings[idx];
                    return _buildBookingCard(context, b, isDark);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ServiceCategoryItem cat, bool isDark) {
    return InkWell(
      onTap: () => _openBookingSheet(context, cat),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _resolveCategoryIcon(cat.iconName),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'from ₹${cat.basePrice}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  cat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cat.services.length} services available',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, bool isDark) {
    final (Color statusColor, String statusLabel) = switch (booking.status) {
      BookingStatus.requested => (AppColors.warning, 'Requested'),
      BookingStatus.assigned => (AppColors.primary, 'Worker Assigned'),
      BookingStatus.inProgress => (Colors.purple, 'In Progress'),
      BookingStatus.completed => (AppColors.success, 'Completed'),
      BookingStatus.cancelled => (AppColors.error, 'Cancelled'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                booking.trackingCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            booking.serviceTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${booking.scheduledDate.day}/${booking.scheduledDate.month} • ${booking.timeSlot}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '₹${booking.totalAmount}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          if (booking.workerName != null) ...<Widget>[
            const Divider(height: 16),
            Row(
              children: <Widget>[
                const Icon(Icons.engineering_rounded, size: 14, color: AppColors.roleWorker),
                const SizedBox(width: 6),
                Text(
                  'Worker: ${booking.workerName}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
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
          content: const Text('Are you sure you want to sign out?'),
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

// -------------------------------------------------------------
// 4-STEP BOOKING FLOW MODAL BOTTOM SHEET
// -------------------------------------------------------------

class _BookingWizardModal extends ConsumerStatefulWidget {
  const _BookingWizardModal({required this.category});

  final ServiceCategoryItem category;

  @override
  ConsumerState<_BookingWizardModal> createState() => _BookingWizardModalState();
}

class _BookingWizardModalState extends ConsumerState<_BookingWizardModal> {
  int _currentStep = 0;
  late String _selectedService;
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(
    text: 'Flat 301, Marvel Residency, Kothrud, Pune - 411038',
  );

  int _dateSelectionIndex = 0; // 0 = Today, 1 = Tomorrow, 2 = Custom
  DateTime _customDate = DateTime.now().add(const Duration(days: 2));
  String _selectedSlot = 'Morning (9 AM - 1 PM)';
  bool _isEmergency = false;

  final List<String> _slots = <String>[
    'Morning (9 AM - 1 PM)',
    'Afternoon (2 PM - 6 PM)',
    'Evening (6 PM - 9 PM)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.category.services.first;
  }

  @override
  void dispose() {
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  DateTime get _effectiveDate {
    if (_dateSelectionIndex == 0) return DateTime.now();
    if (_dateSelectionIndex == 1) return DateTime.now().add(const Duration(days: 1));
    return _customDate;
  }

  int get _baseFare => widget.category.basePrice;
  int get _urgentSurcharge => _isEmergency ? 100 : 0;
  int get _subtotal => _baseFare + _urgentSurcharge;
  int get _welfareFee => (_subtotal * 0.10).round();
  int get _totalAmount => _subtotal + _welfareFee;

  Future<void> _handleConfirmBooking() async {
    final Booking? created =
        await ref.read(customerDashboardProvider.notifier).createNewBooking(
              serviceCategory: widget.category.name,
              serviceTitle: _selectedService,
              serviceDescription: _descController.text.trim(),
              scheduledDate: _effectiveDate,
              timeSlot: _selectedSlot,
              serviceAddress: _addressController.text.trim(),
              isUrgent: _isEmergency,
              baseFare: _baseFare,
            );

    if (!mounted) return;
    Navigator.of(context).pop();

    if (created != null) {
      _showConfirmationDialog(context, created);
    }
  }

  void _showConfirmationDialog(BuildContext context, Booking booking) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'Your cooperative service request has been queued.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      'TRACKING ID',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.trackingCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Estimated Total: ₹${booking.totalAmount} (inclusive of ₹${booking.welfareFee} cooperative pool contribution)',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSubmitting = ref.watch(customerDashboardProvider).isSubmitting;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: <Widget>[
          // Header handle & title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Book ${widget.category.name}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        Text(
                          'Step ${_currentStep + 1} of 4',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Wizard Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: switch (_currentStep) {
                0 => _buildStep1ServiceItem(),
                1 => _buildStep2DateTime(),
                2 => _buildStep3AddressUrgency(),
                _ => _buildStep4CostSummary(isDark),
              },
            ),
          ),

          // Wizard Actions
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: <Widget>[
                  if (_currentStep > 0) ...<Widget>[
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              if (_currentStep < 3) {
                                setState(() => _currentStep++);
                              } else {
                                _handleConfirmBooking();
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_currentStep == 3 ? 'Confirm & Book Service' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: Specific Service Item & Description
  Widget _buildStep1ServiceItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Select Specific Service Item *',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 12),
        ...widget.category.services.map((String service) {
          final bool isSelected = _selectedService == service;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedService = service),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.25),
                    width: isSelected ? 1.8 : 1,
                  ),
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : null,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 18,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Issue Description (Optional)',
            hintText: 'Describe the problem in detail to help the technician arrive prepared...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // STEP 2: Date & Slot Picker
  Widget _buildStep2DateTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Choose Service Date *',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            _buildDateOptionChip(0, 'Today'),
            const SizedBox(width: 8),
            _buildDateOptionChip(1, 'Tomorrow'),
            const SizedBox(width: 8),
            _buildDateOptionChip(2, 'Custom Date'),
          ],
        ),
        if (_dateSelectionIndex == 2) ...<Widget>[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _customDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() => _customDate = picked);
              }
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text('Selected: ${_customDate.day}/${_customDate.month}/${_customDate.year}'),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Select Preferred Time Slot *',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 12),
        ..._slots.map((String slot) {
          final bool isSelected = _selectedSlot == slot;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedSlot = slot),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.25),
                    width: isSelected ? 1.8 : 1,
                  ),
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      isSelected ? Icons.schedule_rounded : Icons.schedule_outlined,
                      size: 18,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      slot,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateOptionChip(int index, String label) {
    final bool isSelected = _dateSelectionIndex == index;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
        selected: isSelected,
        onSelected: (_) => setState(() => _dateSelectionIndex = index),
      ),
    );
  }

  // STEP 3: Address & Emergency / On-Demand Service
  Widget _buildStep3AddressUrgency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Service Location & Address *',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Delivery Address',
            hintText: 'House/Flat No, Landmark, Locality, Pincode...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),

        // Emergency / Urgent dispatch card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isEmergency ? Colors.red.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEmergency ? Colors.red : Colors.grey.withValues(alpha: 0.3),
              width: _isEmergency ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.electric_bolt_rounded,
                color: _isEmergency ? Colors.red : Colors.grey,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Emergency / On-Demand Service',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'Urgent dispatch within 45 mins (+₹100 surcharge)',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isEmergency,
                activeColor: Colors.red,
                onChanged: (bool val) => setState(() => _isEmergency = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 4: Transparent Cost Summary Card
  Widget _buildStep4CostSummary(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Cost Summary & Welfare Breakdown',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Transparent pricing governed by the district cooperative federation.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: <Widget>[
              _buildPriceLine('Selected Service', _selectedService, isHeader: true),
              _buildPriceLine('Scheduled Time', '${_effectiveDate.day}/${_effectiveDate.month} • $_selectedSlot'),
              const Divider(height: 20),
              _buildPriceLine('Standard Base Fare', '₹$_baseFare'),
              if (_isEmergency)
                _buildPriceLine('Urgent Dispatch Surcharge', '+₹$_urgentSurcharge', highlightColor: Colors.red),
              _buildPriceLine(
                'Cooperative Welfare Pool (10%)',
                '+₹$_welfareFee',
                highlightColor: AppColors.success,
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Total Estimated Fare',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    '₹$_totalAmount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Welfare transparency notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.shield_outlined, color: AppColors.success, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'The ₹30-50 welfare contribution goes directly into the registered cooperative worker accident & healthcare pool.',
                  style: TextStyle(fontSize: 11, color: AppColors.success, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceLine(String label, String value, {bool isHeader = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isHeader ? null : Colors.grey[600],
                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlightColor,
            ),
          ),
        ],
      ),
    );
  }
}
