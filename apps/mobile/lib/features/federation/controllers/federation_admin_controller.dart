import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cooperative_society.dart';
import '../../../data/models/worker_profile.dart';
import '../../../data/repositories/federation_admin_repository.dart';

class FederationAdminState {
  const FederationAdminState({
    this.metrics = const FederationMetrics(
      totalWorkers: 0,
      verifiedWorkers: 0,
      pendingVerifications: 0,
      activeCooperatives: 0,
    ),
    this.workers = const <WorkerProfile>[],
    this.cooperatives = const <CooperativeSociety>[],
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.selectedCooperativeId,
    this.isLoading = false,
    this.errorMessage,
  });

  final FederationMetrics metrics;
  final List<WorkerProfile> workers;
  final List<CooperativeSociety> cooperatives;
  final String searchQuery;
  final String statusFilter;
  final String? selectedCooperativeId;
  final bool isLoading;
  final String? errorMessage;

  FederationAdminState copyWith({
    FederationMetrics? metrics,
    List<WorkerProfile>? workers,
    List<CooperativeSociety>? cooperatives,
    String? searchQuery,
    String? statusFilter,
    String? selectedCooperativeId,
    bool? isLoading,
    String? errorMessage,
    bool clearCooperativeFilter = false,
    bool clearError = false,
  }) {
    return FederationAdminState(
      metrics: metrics ?? this.metrics,
      workers: workers ?? this.workers,
      cooperatives: cooperatives ?? this.cooperatives,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedCooperativeId:
          clearCooperativeFilter ? null : (selectedCooperativeId ?? this.selectedCooperativeId),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class FederationAdminNotifier extends Notifier<FederationAdminState> {
  @override
  FederationAdminState build() {
    Future<void>.microtask(loadDashboard);
    return const FederationAdminState(isLoading: true);
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final IFederationAdminRepository repo = ref.read(federationAdminRepositoryProvider);
      final FederationMetrics metrics = await repo.getMetrics();
      final List<CooperativeSociety> coops = await repo.getCooperatives();
      final List<WorkerProfile> workers = await repo.getFilteredWorkers(
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        cooperativeId: state.selectedCooperativeId,
      );

      state = state.copyWith(
        metrics: metrics,
        cooperatives: coops,
        workers: workers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load federation overview: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _reloadWorkers();
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
    _reloadWorkers();
  }

  void setCooperativeFilter(String? cooperativeId) {
    if (cooperativeId == null) {
      state = state.copyWith(clearCooperativeFilter: true);
    } else {
      state = state.copyWith(selectedCooperativeId: cooperativeId);
    }
    _reloadWorkers();
  }

  Future<void> _reloadWorkers() async {
    try {
      final IFederationAdminRepository repo = ref.read(federationAdminRepositoryProvider);
      final List<WorkerProfile> workers = await repo.getFilteredWorkers(
        searchQuery: state.searchQuery,
        statusFilter: state.statusFilter,
        cooperativeId: state.selectedCooperativeId,
      );
      state = state.copyWith(workers: workers);
    } catch (_) {}
  }
}

final NotifierProvider<FederationAdminNotifier, FederationAdminState>
    federationAdminProvider =
    NotifierProvider<FederationAdminNotifier, FederationAdminState>(
  FederationAdminNotifier.new,
  isAutoDispose: true,
);
