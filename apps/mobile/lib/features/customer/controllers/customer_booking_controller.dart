import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../data/models/booking.dart';
import '../../../data/models/service_category.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/repositories/service_catalog_repository.dart';
import '../../auth/controllers/auth_controller.dart';

/// State for the customer dashboard — categories loaded from Supabase DB.
class CustomerDashboardState {
  const CustomerDashboardState({
    this.bookings = const <Booking>[],
    this.categories = const <ServiceCategory>[],
    this.searchQuery = '',
    this.selectedCategory,
    this.isLoading = false,
    this.isCatalogLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<Booking> bookings;
  final List<ServiceCategory> categories;
  final String searchQuery;
  final String? selectedCategory;
  final bool isLoading;
  final bool isCatalogLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  List<ServiceCategory> get filteredCategories {
    if (searchQuery.isEmpty) return categories;
    final String q = searchQuery.toLowerCase();
    return categories.where((ServiceCategory cat) {
      final bool matchesCat = cat.name.toLowerCase().contains(q);
      final bool matchesService =
          cat.services.any((Service s) => s.name.toLowerCase().contains(q));
      return matchesCat || matchesService;
    }).toList();
  }

  CustomerDashboardState copyWith({
    List<Booking>? bookings,
    List<ServiceCategory>? categories,
    String? searchQuery,
    String? selectedCategory,
    bool? isLoading,
    bool? isCatalogLoading,
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
      isCatalogLoading: isCatalogLoading ?? this.isCatalogLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class CustomerDashboardNotifier extends AutoDisposeNotifier<CustomerDashboardState> {
  @override
  CustomerDashboardState build() {
    const CustomerDashboardState stateObj = CustomerDashboardState(isLoading: true, isCatalogLoading: true);
    Future<void>.microtask(() async {
      await Future.wait(<Future<void>>[
        loadServiceCatalog(),
        loadCustomerBookings(),
      ]);
    });
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

  /// Load service categories and services from Supabase.
  Future<void> loadCategories() => loadServiceCatalog();

  Future<void> loadServiceCatalog() async {
    state = state.copyWith(isCatalogLoading: true);
    try {
      final IServiceCatalogRepository catalog = ref.read(serviceCatalogRepositoryProvider);
      final List<ServiceCategory> categories = await catalog.getCategories();
      state = state.copyWith(categories: categories, isCatalogLoading: false);
    } catch (e) {
      state = state.copyWith(
        isCatalogLoading: false,
        errorMessage: 'Failed to load service catalog: $e',
      );
    }
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
    String? serviceId,
    double? customerLatitude,
    double? customerLongitude,
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
        serviceCategory: serviceCategory,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        serviceId: serviceId,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
        serviceAddress: serviceAddress,
        isUrgent: isUrgent,
        baseFare: subtotal,
        welfareFee: welfareFee,
        totalAmount: totalAmount,
        customerLatitude: customerLatitude,
        customerLongitude: customerLongitude,
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

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      await repo.cancelBooking(bookingId: bookingId, reason: reason);
      await loadCustomerBookings();
      state = state.copyWith(successMessage: 'Booking cancelled.');
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to cancel booking: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      await repo.updateBookingStatus(
        bookingId: bookingId,
        status: status,
      );
      await loadCustomerBookings();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update booking status: $e');
    }
  }

  Future<void> submitReview({
    required String bookingId,
    required String workerId,
    required int rating,
    String comment = '',
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final IReviewRepository repo = ref.read(reviewRepositoryProvider);
      await repo.submitReview(
        bookingId: bookingId,
        reviewerId: _currentCustomerId,
        workerId: workerId,
        rating: rating,
        comment: comment,
      );
      await loadCustomerBookings();
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Review submitted successfully. Thank you!',
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit review: $e',
      );
    }
  }
}

final AutoDisposeNotifierProvider<CustomerDashboardNotifier, CustomerDashboardState>
    customerDashboardProvider =
    NotifierProvider.autoDispose<CustomerDashboardNotifier, CustomerDashboardState>(
  CustomerDashboardNotifier.new,
);
