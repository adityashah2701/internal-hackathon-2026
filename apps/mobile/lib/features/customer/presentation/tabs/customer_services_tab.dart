import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/service_category.dart';
import '../../controllers/customer_booking_controller.dart';
import '../../utils/service_image_helper.dart';
import '../../../common/presentation/widgets/empty_state.dart';

class CustomerServicesTab extends ConsumerWidget {
  const CustomerServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomerDashboardState dashState = ref.watch(customerDashboardProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: <Widget>[
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: dashState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref.read(customerDashboardProvider.notifier).setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: (String value) => ref.read(customerDashboardProvider.notifier).setSearchQuery(value),
            ),
          ),
          // Content
          Expanded(
            child: dashState.isCatalogLoading
                ? const Center(child: CircularProgressIndicator())
                : dashState.filteredCategories.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.search_off,
                        title: 'No services found',
                        subtitle: dashState.searchQuery.isNotEmpty
                            ? 'Try a different search term.'
                            : 'Service categories will appear here once configured.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(customerDashboardProvider.notifier).loadServiceCatalog(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: dashState.filteredCategories.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ServiceCategory cat = dashState.filteredCategories[index];
                            return _buildCategorySection(context, ref, cat, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, WidgetRef ref, ServiceCategory category, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.network(
                    ServiceImageHelper.getCategoryImageUrl(category.name),
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext ctx, Object err, StackTrace? stack) => Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      category.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (category.description.isNotEmpty)
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (category.basePrice > 0)
                Text(
                  'from ₹${category.basePrice}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
        ),
        if (category.services.isNotEmpty)
          ...category.services.map((Service s) => _buildServiceTile(context, ref, category, s, isDark)),
        if (category.services.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44, bottom: 8),
            child: Text(
              'No services available in this category.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildServiceTile(BuildContext context, WidgetRef ref, ServiceCategory category, Service service, bool isDark) {
    final String serviceImageUrl = ServiceImageHelper.getServiceImageUrl(category.name, service.name);

    return Card(
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Image.network(
              serviceImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext ctx, Object err, StackTrace? stack) => Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: const Icon(Icons.handyman_outlined, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ),
        title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (service.description.isNotEmpty)
              Text(
                service.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Text(
                  '₹${service.basePriceInr}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  '~${service.estimatedDurationMinutes} min',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: () {
            _showBookingSheet(context, ref, category, service);
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
          ),
          child: const Text('Book', style: TextStyle(fontSize: 13)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }

  void _showBookingSheet(BuildContext context, WidgetRef ref, ServiceCategory category, Service service) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTimeSlot = 'Morning (9 AM - 1 PM)';
    String serviceAddress = '';
    bool isUrgent = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Photography Banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image.network(
                          ServiceImageHelper.getServiceImageUrl(category.name, service.name),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Book ${service.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      '${category.name} • ₹${service.basePriceInr}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    // Date Selector
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                      title: const Text('Service Date'),
                      subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    // Time Slot
                    DropdownButtonFormField<String>(
                      value: selectedTimeSlot,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(value: 'Morning (9 AM - 1 PM)', child: Text('Morning (9 AM - 1 PM)')),
                        DropdownMenuItem<String>(value: 'Afternoon (1 PM - 5 PM)', child: Text('Afternoon (1 PM - 5 PM)')),
                        DropdownMenuItem<String>(value: 'Evening (5 PM - 9 PM)', child: Text('Evening (5 PM - 9 PM)')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) setSheetState(() => selectedTimeSlot = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Service Address
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Service Address',
                        hintText: 'Enter full address for the service',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      onChanged: (String value) => serviceAddress = value,
                    ),
                    const SizedBox(height: 16),
                    // Urgent Toggle
                    SwitchListTile(
                      title: const Text('Emergency / Urgent'),
                      subtitle: const Text('+₹100 emergency surcharge'),
                      value: isUrgent,
                      onChanged: (bool value) => setSheetState(() => isUrgent = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    // Confirm Button
                    FilledButton(
                      onPressed: serviceAddress.trim().isEmpty
                          ? null
                          : () async {
                              final Booking? created = await ref.read(customerDashboardProvider.notifier).createNewBooking(
                                serviceCategory: category.name,
                                serviceTitle: service.name,
                                serviceDescription: service.description,
                                scheduledDate: selectedDate,
                                timeSlot: selectedTimeSlot,
                                serviceAddress: serviceAddress.trim(),
                                isUrgent: isUrgent,
                                baseFare: service.basePriceInr,
                                serviceId: service.id,
                              );
                              if (context.mounted && created != null) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Booking created: ${created.trackingCode}'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                // Go to bookings tab
                                context.go('/customer/bookings');
                              }
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
