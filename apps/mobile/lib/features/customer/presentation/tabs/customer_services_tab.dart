import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/service_category.dart';
import '../../controllers/customer_booking_controller.dart';
import '../customer_home_screen.dart';

class CustomerServicesTab extends ConsumerStatefulWidget {
  const CustomerServicesTab({super.key});

  @override
  ConsumerState<CustomerServicesTab> createState() => _CustomerServicesTabState();
}

class _CustomerServicesTabState extends ConsumerState<CustomerServicesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filterChips = <String>[
    'All',
    'Electrical',
    'Plumbing',
    'Carpentry',
    'AC & Appliances',
    'Painting',
  ];

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

  void _openBookingForCategory(BuildContext context, ServiceCategory category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        return BookingWizardModal(category: category);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomerDashboardState state = ref.watch(customerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<ServiceCategory> displayedCategories = state.categories.where((ServiceCategory cat) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Electrical') return cat.name.toLowerCase().contains('elec');
      if (_selectedFilter == 'Plumbing') return cat.name.toLowerCase().contains('plumb');
      if (_selectedFilter == 'Carpentry') return cat.name.toLowerCase().contains('carp');
      if (_selectedFilter == 'AC & Appliances') {
        return cat.name.toLowerCase().contains('ac') || cat.name.toLowerCase().contains('appliance');
      }
      if (_selectedFilter == 'Painting') return cat.name.toLowerCase().contains('paint');
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Directory', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (String val) {
                ref.read(customerDashboardProvider.notifier).setSearchQuery(val.trim());
              },
              decoration: InputDecoration(
                hintText: 'Search trades, repairs, or appliances...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(customerDashboardProvider.notifier).loadCategories();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Filter Chips Horizontal Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterChips.map((String chip) {
                  final bool isSelected = _selectedFilter == chip;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(chip),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.onPrimary
                            : (isDark ? Colors.white70 : const Color(0xFF374151)),
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() => _selectedFilter = chip);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Fair Wage Guarantee Callout
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFFB45309), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Cooperative Fair Wage Standards',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.primaryLight : const Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rates adhere to State Labour Board benchmarks. 100% of labour charge goes directly to the worker + 5% welfare pool.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Available Trades (${displayedCategories.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Instant Dispatch',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryLight : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Categories List
            if (displayedCategories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No trades match your search.',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              )
            else
              ...displayedCategories.map((ServiceCategory cat) {
                return _buildCategoryCard(context, cat, isDark);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ServiceCategory cat, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_resolveCategoryIcon(cat.iconName), color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        cat.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cat.description.isNotEmpty
                            ? cat.description
                            : 'Verified union craftsman services with state warranty.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    const Text('From', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(
                      '₹${cat.basePrice}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Services Pills inside category
            if (cat.services.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: cat.services.take(4).map((Service s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _openBookingForCategory(context, cat),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Book ${cat.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
