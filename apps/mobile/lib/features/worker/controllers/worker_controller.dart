import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../data/models/booking.dart';
import '../../../data/models/cooperative_society.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/worker_document.dart';
import '../../../data/models/worker_profile.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class WorkerDashboardState {
  const WorkerDashboardState({
    required this.profile,
    this.documents = const <WorkerDocument>[],
    this.societies = const <CooperativeSociety>[],
    this.availableBookings = const <Booking>[],
    this.activeBookings = const <Booking>[],
    this.historicalBookings = const <Booking>[],
    this.isLoading = false,
    this.isActionInProgress = false,
    this.errorMessage,
    this.successMessage,
  });

  final WorkerProfile profile;
  final List<WorkerDocument> documents;
  final List<CooperativeSociety> societies;
  final List<Booking> availableBookings;
  final List<Booking> activeBookings;
  final List<Booking> historicalBookings;
  final bool isLoading;
  final bool isActionInProgress;
  final String? errorMessage;
  final String? successMessage;

  WorkerDashboardState copyWith({
    WorkerProfile? profile,
    List<WorkerDocument>? documents,
    List<CooperativeSociety>? societies,
    List<Booking>? availableBookings,
    List<Booking>? activeBookings,
    List<Booking>? historicalBookings,
    bool? isLoading,
    bool? isActionInProgress,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return WorkerDashboardState(
      profile: profile ?? this.profile,
      documents: documents ?? this.documents,
      societies: societies ?? this.societies,
      availableBookings: availableBookings ?? this.availableBookings,
      activeBookings: activeBookings ?? this.activeBookings,
      historicalBookings: historicalBookings ?? this.historicalBookings,
      isLoading: isLoading ?? this.isLoading,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class WorkerDashboardNotifier extends AutoDisposeNotifier<WorkerDashboardState> {
  @override
  WorkerDashboardState build() {
    final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
    final String userId = switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile.id,
      AuthOnboardingRequired(:final sb.User user) => user.id,
      _ => '',
    };

    final WorkerDashboardState initial = WorkerDashboardState(
      profile: WorkerProfile(id: userId),
      isLoading: true,
    );

    if (userId.isNotEmpty) {
      Future<void>.microtask(loadDashboard);
    }

    return initial;
  }

  String get _currentUserId {
    final AsyncValue<AppAuthState> authAsync = ref.read(authControllerProvider);
    return switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile.id,
      AuthOnboardingRequired(:final sb.User user) => user.id,
      _ => '',
    };
  }

  Future<void> loadDashboard() async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);
      final WorkerProfile profile = await repo.getWorkerProfile(userId);
      final List<WorkerDocument> documents = await repo.getDocuments(userId);
      final List<CooperativeSociety> societies = await repo.getCooperatives();

      state = state.copyWith(
        profile: profile,
        documents: documents,
        societies: societies,
        isLoading: false,
      );

      // Load bookings separately to not block profile loading
      await loadBookings();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load worker workspace. Please retry.',
      );
    }
  }

  Future<void> loadBookings() async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    try {
      final IBookingRepository bookingRepo = ref.read(bookingRepositoryProvider);
      
      // 1. Available (requested, unassigned, matching skills)
      final List<Booking> available = await bookingRepo.getAvailableBookingsForWorker(
        workerId: userId,
        skills: state.profile.skills,
      );

      // 2. My Bookings (assigned to me)
      final List<Booking> myBookings = await bookingRepo.getWorkerBookings(userId);
      
      final List<Booking> active = myBookings.where((Booking b) => b.status.isActive).toList();
      final List<Booking> historical = myBookings.where((Booking b) => b.status.isTerminal || b.status == BookingStatus.completed || b.status == BookingStatus.paymentConfirmed).toList();

      state = state.copyWith(
        availableBookings: available,
        activeBookings: active,
        historicalBookings: historical,
      );
    } catch (e) {
      // Don't set error message as this is a background load
    }
  }

  Future<void> updateProfileDetails({
    required List<String> skills,
    required int experienceYears,
    required int dailyRateInr,
    required String serviceArea,
    required String bio,
    String? cooperativeId,
  }) async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    state = state.copyWith(isActionInProgress: true, clearError: true, clearSuccess: true);
    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);
      final WorkerProfile updated = state.profile.copyWith(
        skills: skills,
        experienceYears: experienceYears,
        dailyRateInr: dailyRateInr,
        serviceArea: serviceArea,
        bio: bio,
        cooperativeId: cooperativeId,
      );

      final WorkerProfile result = await repo.updateWorkerProfile(updated);
      state = state.copyWith(
        profile: result,
        isActionInProgress: false,
        successMessage: 'Trade profile updated successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Failed to update trade details: $e',
      );
    }
  }

  Future<void> uploadDocument({
    required DocumentType documentType,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    state = state.copyWith(isActionInProgress: true, clearError: true, clearSuccess: true);
    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);
      final WorkerDocument newDoc = await repo.uploadDocument(
        workerId: userId,
        documentType: documentType,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );

      final List<WorkerDocument> updatedDocs = List<WorkerDocument>.from(state.documents)..insert(0, newDoc);
      state = state.copyWith(
        documents: updatedDocs,
        isActionInProgress: false,
        successMessage: '${documentType.displayName} uploaded successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Document upload failed: $e',
      );
    }
  }

  Future<void> deleteDocument(String documentId, String filePath) async {
    state = state.copyWith(isActionInProgress: true, clearError: true);
    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);
      await repo.deleteDocument(documentId: documentId, filePath: filePath);
      final List<WorkerDocument> updatedDocs =
          state.documents.where((WorkerDocument doc) => doc.id != documentId).toList();
      state = state.copyWith(
        documents: updatedDocs,
        isActionInProgress: false,
        successMessage: 'Document removed.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Could not delete document: $e',
      );
    }
  }

  Future<void> toggleAvailability(bool isAvailable) async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    state = state.copyWith(
      profile: state.profile.copyWith(isAvailable: isAvailable),
      clearError: true,
      clearSuccess: true,
    );

    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);
      final WorkerProfile updated = await repo.toggleAvailability(
        workerId: userId,
        isAvailable: isAvailable,
      );
      state = state.copyWith(
        profile: updated,
        successMessage: isAvailable ? 'You are now ON-DUTY (Open for cooperative jobs).' : 'You are now OFF-DUTY.',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update availability status: $e',
      );
    }
  }

  Future<void> updateSkillProfile({
    required List<String> skills,
    required int experienceYears,
    required int hourlyRateInr,
    int? dailyRateInr,
  }) async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    state = state.copyWith(isActionInProgress: true, clearError: true, clearSuccess: true);
    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);
      final WorkerProfile updated = state.profile.copyWith(
        skills: skills,
        experienceYears: experienceYears,
        hourlyRateInr: hourlyRateInr,
        dailyRateInr: dailyRateInr ?? state.profile.dailyRateInr,
      );

      final WorkerProfile result = await repo.updateWorkerProfile(updated);
      state = state.copyWith(
        profile: result,
        isActionInProgress: false,
        successMessage: 'Trade skills and hourly rate updated successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Failed to update skill profile: $e',
      );
    }
  }

  Future<void> submitForVerification() async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    if (state.documents.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please upload at least one identity or trade certificate document before submitting.',
      );
      return;
    }

    if (state.profile.skills.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select at least one trade skill before submitting.',
      );
      return;
    }

    state = state.copyWith(isActionInProgress: true, clearError: true, clearSuccess: true);
    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);
      final WorkerProfile updated = await repo.submitForVerification(userId);
      state = state.copyWith(
        profile: updated,
        isActionInProgress: false,
        successMessage: 'Verification request submitted! Your cooperative society will review your application.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Failed to submit verification: $e',
      );
    }
  }

  // --- Booking Actions ---

  Future<void> acceptBooking(String bookingId) async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    state = state.copyWith(isActionInProgress: true, clearError: true);
    try {
      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      await repo.acceptBooking(bookingId: bookingId, workerId: userId);
      await loadBookings();
      state = state.copyWith(
        isActionInProgress: false,
        successMessage: 'Booking accepted successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Failed to accept booking: $e',
      );
    }
  }

  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    final String userId = _currentUserId;
    if (userId.isEmpty) return;

    state = state.copyWith(isActionInProgress: true, clearError: true);
    try {
      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      await repo.rejectBooking(bookingId: bookingId, reason: reason);
      await loadBookings();
      state = state.copyWith(
        isActionInProgress: false,
        successMessage: 'Booking rejected.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Failed to reject booking: $e',
      );
    }
  }

  Future<void> startJob(String bookingId) async {
    state = state.copyWith(isActionInProgress: true, clearError: true);
    try {
      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      await repo.startJob(bookingId);
      await loadBookings();
      state = state.copyWith(
        isActionInProgress: false,
        successMessage: 'Job started. Please ensure safety protocols.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Failed to start job: $e',
      );
    }
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    state = state.copyWith(isActionInProgress: true, clearError: true);
    try {
      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      await repo.updateBookingStatus(bookingId: bookingId, status: status);
      await loadBookings();
      state = state.copyWith(
        isActionInProgress: false,
        successMessage: 'Status updated.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Failed to update status: $e',
      );
    }
  }

  Future<void> completeJob(String bookingId) async {
    state = state.copyWith(isActionInProgress: true, clearError: true);
    try {
      final IBookingRepository repo = ref.read(bookingRepositoryProvider);
      await repo.completeJob(bookingId);
      await loadBookings();
      state = state.copyWith(
        isActionInProgress: false,
        successMessage: 'Job marked as completed. Awaiting payment confirmation.',
      );
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: 'Failed to complete job: $e',
      );
    }
  }
}

final AutoDisposeNotifierProvider<WorkerDashboardNotifier, WorkerDashboardState> workerDashboardProvider =
    NotifierProvider.autoDispose<WorkerDashboardNotifier, WorkerDashboardState>(
  WorkerDashboardNotifier.new,
);
