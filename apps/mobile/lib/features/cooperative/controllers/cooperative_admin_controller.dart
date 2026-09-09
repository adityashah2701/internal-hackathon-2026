import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../data/models/worker_document.dart';
import '../../../data/models/worker_profile.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/cooperative_admin_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class CooperativeAdminState {
  const CooperativeAdminState({
    this.workers = const <WorkerProfile>[],
    this.selectedWorkerDocs = const <WorkerDocument>[],
    this.activeFilter = 'pending',
    this.activeWorkersCount = 14,
    this.totalBookingsCompleted = 38,
    this.societyWelfarePoolInr = 18450,
    this.isLoading = false,
    this.isProcessing = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<WorkerProfile> workers;
  final List<WorkerDocument> selectedWorkerDocs;
  final String activeFilter;
  final int activeWorkersCount;
  final int totalBookingsCompleted;
  final int societyWelfarePoolInr;
  final bool isLoading;
  final bool isProcessing;
  final String? errorMessage;
  final String? successMessage;

  int get pendingCount =>
      workers.where((WorkerProfile w) => w.verificationStatus == WorkerVerificationStatus.pending).length;

  CooperativeAdminState copyWith({
    List<WorkerProfile>? workers,
    List<WorkerDocument>? selectedWorkerDocs,
    String? activeFilter,
    int? activeWorkersCount,
    int? totalBookingsCompleted,
    int? societyWelfarePoolInr,
    bool? isLoading,
    bool? isProcessing,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CooperativeAdminState(
      workers: workers ?? this.workers,
      selectedWorkerDocs: selectedWorkerDocs ?? this.selectedWorkerDocs,
      activeFilter: activeFilter ?? this.activeFilter,
      activeWorkersCount: activeWorkersCount ?? this.activeWorkersCount,
      totalBookingsCompleted: totalBookingsCompleted ?? this.totalBookingsCompleted,
      societyWelfarePoolInr: societyWelfarePoolInr ?? this.societyWelfarePoolInr,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class CooperativeAdminNotifier extends AutoDisposeNotifier<CooperativeAdminState> {
  @override
  CooperativeAdminState build() {
    Future<void>.microtask(loadWorkers);
    return const CooperativeAdminState(isLoading: true);
  }

  String get _adminId {
    final AsyncValue<AppAuthState> authAsync = ref.read(authControllerProvider);
    return switch (authAsync.value) {
      AuthAuthenticated(:final sb.User user) => user.id,
      _ => 'admin',
    };
  }

  Future<void> loadWorkers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ICooperativeAdminRepository repo = ref.read(cooperativeAdminRepositoryProvider);
      final List<WorkerProfile> list = await repo.getWorkers(statusFilter: state.activeFilter);
      
      Map<String, int>? metrics;
      try {
        metrics = await ref.read(bookingRepositoryProvider).getWelfareMetrics();
      } catch (_) {}

      state = state.copyWith(
        workers: list,
        activeWorkersCount: metrics != null ? metrics['activeWorkers'] : state.activeWorkersCount,
        totalBookingsCompleted: metrics != null ? metrics['completedBookings'] : state.totalBookingsCompleted,
        societyWelfarePoolInr: metrics != null ? metrics['welfarePoolInr'] : state.societyWelfarePoolInr,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch worker verifications: $e',
      );
    }
  }

  void setFilter(String filter) {
    if (state.activeFilter == filter) return;
    state = state.copyWith(activeFilter: filter);
    loadWorkers();
  }

  Future<List<WorkerDocument>> loadWorkerDocuments(String workerId) async {
    try {
      final ICooperativeAdminRepository repo = ref.read(cooperativeAdminRepositoryProvider);
      final List<WorkerDocument> docs = await repo.getWorkerDocuments(workerId);
      state = state.copyWith(selectedWorkerDocs: docs);
      return docs;
    } catch (e) {
      return <WorkerDocument>[];
    }
  }

  Future<String?> inspectDocumentPayload(String filePath) async {
    try {
      final ICooperativeAdminRepository repo = ref.read(cooperativeAdminRepositoryProvider);
      return await repo.getDocumentPayload(filePath);
    } catch (_) {
      return null;
    }
  }

  Future<bool> approveWorker(String workerId) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      final ICooperativeAdminRepository repo = ref.read(cooperativeAdminRepositoryProvider);
      final WorkerProfile updated = await repo.approveWorker(
        workerId: workerId,
        adminId: _adminId,
      );

      final List<WorkerProfile> updatedList = state.workers.map((WorkerProfile w) {
        return w.id == workerId ? updated : w;
      }).toList();

      state = state.copyWith(
        workers: updatedList,
        isProcessing: false,
        successMessage: 'Worker ${updated.displayName} has been certified & approved!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Approval failed: $e',
      );
      return false;
    }
  }

  Future<bool> rejectWorker(String workerId, String reason) async {
    if (reason.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'A reason is required to reject verification.');
      return false;
    }

    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      final ICooperativeAdminRepository repo = ref.read(cooperativeAdminRepositoryProvider);
      final WorkerProfile updated = await repo.rejectWorker(
        workerId: workerId,
        adminId: _adminId,
        reason: reason,
      );

      final List<WorkerProfile> updatedList = state.workers.map((WorkerProfile w) {
        return w.id == workerId ? updated : w;
      }).toList();

      state = state.copyWith(
        workers: updatedList,
        isProcessing: false,
        successMessage: 'Application rejected with notification sent to worker.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Rejection failed: $e',
      );
      return false;
    }
  }
}

final AutoDisposeNotifierProvider<CooperativeAdminNotifier, CooperativeAdminState>
    cooperativeAdminProvider =
    NotifierProvider.autoDispose<CooperativeAdminNotifier, CooperativeAdminState>(
  CooperativeAdminNotifier.new,
);
