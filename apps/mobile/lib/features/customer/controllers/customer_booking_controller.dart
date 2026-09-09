import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../data/models/booking.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class ServiceCategoryItem {
  const ServiceCategoryItem({
    required this.id,
    required this.name,
    required this.iconName,
    required this.basePrice,
    required this.services,
  });

  final String id;
  final String name;
  final String iconName;
  final int basePrice;
  final List<String> services;

  static const List<ServiceCategoryItem> defaultCategories = <ServiceCategoryItem>[
    ServiceCategoryItem(
      id: 'electrician',
      name: 'Electrician',
      iconName: 'flash_on_rounded',
      basePrice: 350,
      services: <String>[
        'MCB & Switchboard Repair',
        'Ceiling Fan Installation & Repair',
        'Complete House Wiring Diagnostics',
        'Inverter & Backup Battery Setup',
        'Lighting & Chandelier Fixtures',
      ],
    ),
    ServiceCategoryItem(
      id: 'plumber',
      name: 'Plumber',
      iconName: 'water_drop_rounded',
      basePrice: 350,
      services: <String>[
        'Pipe Leakage & Burst Diagnostics',
        'Tap & Shower Fitting Replacement',
        'Drain Cleaning & Blockage Clearing',
        'Water Tank Valve & Motor Repair',
        'Sanitary Ware & Commode Installation',
      ],
    ),
    ServiceCategoryItem(
      id: 'carpenter',
      name: 'Carpenter',
      iconName: 'handyman_rounded',
      basePrice: 400,
      services: <String>[
        'Door Lock, Latch & Hinge Alignment',
        'Furniture Assembly & Repair',
        'Modular Kitchen Cabinet Fixes',
        'Custom Wooden Shelving',
        'Window Frame & Mesh Repairs',
      ],
    ),
    ServiceCategoryItem(
      id: 'cleaning',
      name: 'Cleaning',
      iconName: 'cleaning_services_rounded',
      basePrice: 450,
      services: <String>[
        'Deep Home Sanitation',
        'Kitchen Exhaust & Degreasing',
        'Bathroom Scrubbing & Scaling',
        'Sofa & Upholstery Shampooing',
        'Post-Renovation Clean-up',
      ],
    ),
    ServiceCategoryItem(
      id: 'caregiver',
      name: 'Caregiver',
      iconName: 'volunteer_activism_rounded',
      basePrice: 500,
      services: <String>[
        'Elderly Day Assistance & Vitals',
        'Post-Operative Patient Care',
        'Physiotherapy Assistance',
        'Companion & Mobility Support',
        'Emergency Medical Escort',
      ],
    ),
    ServiceCategoryItem(
      id: 'appliance',
      name: 'Appliance Repair',
      iconName: 'devices_other_rounded',
      basePrice: 400,
      services: <String>[
        'Washing Machine Diagnostics',
        'Refrigerator Gas & Cooling Fix',
        'Microwave Oven Repair',
        'RO Water Purifier Service & Filter',
        'AC Servicing & Gas Refill',
      ],
    ),
    ServiceCategoryItem(
      id: 'painter',
      name: 'Painter',
      iconName: 'format_paint_rounded',
      basePrice: 450,
      services: <String>[
        'Single Room Waterproof Emulsion',
        'Full Home Interior Painting',
        'Wall Crack Filling & Putty Work',
        'Wood & Metal Enamel Polish',
        'Exterior Weatherproof Coat',
      ],
    ),
  ];
}

class CustomerDashboardState {
  const CustomerDashboardState({
    this.bookings = const <Booking>[],
    this.categories = ServiceCategoryItem.defaultCategories,
    this.searchQuery = '',
    this.selectedCategory,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<Booking> bookings;
  final List<ServiceCategoryItem> categories;
  final String searchQuery;
  final String? selectedCategory;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  List<ServiceCategoryItem> get filteredCategories {
    if (searchQuery.isEmpty) return categories;
    final String q = searchQuery.toLowerCase();
    return categories.where((ServiceCategoryItem cat) {
      final bool matchesCat = cat.name.toLowerCase().contains(q);
      final bool matchesService = cat.services.any((String s) => s.toLowerCase().contains(q));
      return matchesCat || matchesService;
    }).toList();
  }

  CustomerDashboardState copyWith({
    List<Booking>? bookings,
    List<ServiceCategoryItem>? categories,
    String? searchQuery,
    String? selectedCategory,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearCategory = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CustomerDashboardState(
      bookings: bookings ?? this.bookings,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class CustomerDashboardNotifier extends AutoDisposeNotifier<CustomerDashboardState> {
  @override
  CustomerDashboardState build() {
    const CustomerDashboardState stateObj = CustomerDashboardState(isLoading: true);
    Future<void>.microtask(loadCustomerBookings);
    return stateObj;
  }

  String get _currentCustomerId {
    final AsyncValue<AppAuthState> authAsync = ref.read(authControllerProvider);
    return switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile.id,
      AuthOnboardingRequired(:final sb.User user) => user.id,
      _ => '',
    };
  }

  Future<void> loadCustomerBookings() async {
    final String customerId = _currentCustomerId;
    if (customerId.isEmpty) {
      state = state.copyWith(bookings: const <Booking>[], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      final List<Booking> bookings = await repo.getCustomerBookings(customerId);
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load bookings: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCategory(String? categoryId) {
    if (categoryId == null || state.selectedCategory == categoryId) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: categoryId);
    }
  }

  Future<Booking?> createNewBooking({
    required String serviceCategory,
    required String serviceTitle,
    required String serviceDescription,
    required DateTime scheduledDate,
    required String timeSlot,
    required String serviceAddress,
    required bool isUrgent,
    required int baseFare,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final int emergencyFee = isUrgent ? 100 : 0;
      final int subtotal = baseFare + emergencyFee;
      final int welfareFee = (subtotal * 0.10).round(); // 10% cooperative welfare pool
      final int totalAmount = subtotal + welfareFee;

      final Booking newBooking = Booking(
        id: '',
        trackingCode: '',
        customerId: _currentCustomerId,
        customerName: 'Customer',
        serviceCategory: serviceCategory,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
        serviceAddress: serviceAddress,
        isUrgent: isUrgent,
        baseFare: subtotal,
        welfareFee: welfareFee,
        totalAmount: totalAmount,
        status: BookingStatus.requested,
      );

      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      final Booking created = await repo.createBooking(newBooking);

      final List<Booking> updatedList = List<Booking>.from(state.bookings)..insert(0, created);
      state = state.copyWith(
        bookings: updatedList,
        isSubmitting: false,
        successMessage: 'Booking created with Tracking ID: ${created.trackingCode}',
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to create booking: $e',
      );
      return null;
    }
  }
}

final AutoDisposeNotifierProvider<CustomerDashboardNotifier, CustomerDashboardState>
    customerDashboardProvider =
    NotifierProvider.autoDispose<CustomerDashboardNotifier, CustomerDashboardState>(
  CustomerDashboardNotifier.new,
);
