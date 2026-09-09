import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/app_config.dart';
import '../../../core/network/supabase_client.dart';
import '../../../data/models/cooperative_society.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/worker_document.dart';
import '../../../data/models/worker_profile.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../auth/controllers/auth_controller.dart';

enum SupabaseConnectivityStatus {
  notConfigured,
  connecting,
  connected,
  unreachable,
}

class DiagnosticsState {
  const DiagnosticsState({
    required this.isConfigured,
    required this.sanitizedHost,
    required this.environment,
    required this.appVersion,
    required this.connectivityStatus,
    required this.hasActiveAuthSession,
    this.errorMessage,
  });

  final bool isConfigured;
  final String sanitizedHost;
  final String environment;
  final String appVersion;
  final SupabaseConnectivityStatus connectivityStatus;
  final bool hasActiveAuthSession;
  final String? errorMessage;
}

class DiagnosticsNotifier extends AutoDisposeNotifier<DiagnosticsState> {
  @override
  DiagnosticsState build() {
    final bool configured = AppConfig.isSupabaseConfigured;
    final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);

    final DiagnosticsState initialState = DiagnosticsState(
      isConfigured: configured,
      sanitizedHost: AppConfig.sanitizedSupabaseHost,
      environment: AppConfig.environment.name,
      appVersion: AppConfig.appVersion,
      connectivityStatus: configured
          ? SupabaseConnectivityStatus.connecting
          : SupabaseConnectivityStatus.notConfigured,
      hasActiveAuthSession: client?.auth.currentSession != null,
    );

    if (configured && client != null) {
      Future<void>.microtask(checkConnectivity);
    }

    return initialState;
  }

  Future<void> checkConnectivity() async {
    final sb.SupabaseClient? client = ref.read(supabaseClientProvider);
    if (client == null) {
      state = DiagnosticsState(
        isConfigured: false,
        sanitizedHost: AppConfig.sanitizedSupabaseHost,
        environment: AppConfig.environment.name,
        appVersion: AppConfig.appVersion,
        connectivityStatus: SupabaseConnectivityStatus.notConfigured,
        hasActiveAuthSession: false,
      );
      return;
    }

    state = DiagnosticsState(
      isConfigured: true,
      sanitizedHost: AppConfig.sanitizedSupabaseHost,
      environment: AppConfig.environment.name,
      appVersion: AppConfig.appVersion,
      connectivityStatus: SupabaseConnectivityStatus.connecting,
      hasActiveAuthSession: client.auth.currentSession != null,
    );

    try {
      await client.from('_health_check_dummy_').select().limit(1).maybeSingle();
      state = DiagnosticsState(
        isConfigured: true,
        sanitizedHost: AppConfig.sanitizedSupabaseHost,
        environment: AppConfig.environment.name,
        appVersion: AppConfig.appVersion,
        connectivityStatus: SupabaseConnectivityStatus.connected,
        hasActiveAuthSession: client.auth.currentSession != null,
      );
    } on sb.PostgrestException catch (e) {
      state = DiagnosticsState(
        isConfigured: true,
        sanitizedHost: AppConfig.sanitizedSupabaseHost,
        environment: AppConfig.environment.name,
        appVersion: AppConfig.appVersion,
        connectivityStatus: SupabaseConnectivityStatus.connected,
        hasActiveAuthSession: client.auth.currentSession != null,
        errorMessage: e.code == 'PGRST204' || e.code == '42P01' || e.code == 'PGRST205' ? null : e.message,
      );
    } catch (_) {
      state = DiagnosticsState(
        isConfigured: true,
        sanitizedHost: AppConfig.sanitizedSupabaseHost,
        environment: AppConfig.environment.name,
        appVersion: AppConfig.appVersion,
        connectivityStatus: SupabaseConnectivityStatus.unreachable,
        hasActiveAuthSession: client.auth.currentSession != null,
        errorMessage: 'Backend is unreachable or offline',
      );
    }
  }
}

final AutoDisposeNotifierProvider<DiagnosticsNotifier, DiagnosticsState> diagnosticsProvider =
    NotifierProvider.autoDispose<DiagnosticsNotifier, DiagnosticsState>(
  DiagnosticsNotifier.new,
);

// -------------------------------------------------------------
// WORKER REGISTRATION & VERIFICATION WIZARD STATE
// -------------------------------------------------------------

class WorkerVerificationWizardState {
  const WorkerVerificationWizardState({
    this.currentStep = 0,
    this.fullName = '',
    this.phoneNumber = '',
    this.selectedCooperativeId,
    this.societies = const <CooperativeSociety>[],
    this.selectedDocType = DocumentType.aadhaar,
    this.fileName,
    this.fileBytes,
    this.mimeType = 'image/jpeg',
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.isCompleted = false,
  });

  final int currentStep;
  final String fullName;
  final String phoneNumber;
  final String? selectedCooperativeId;
  final List<CooperativeSociety> societies;
  final DocumentType selectedDocType;
  final String? fileName;
  final List<int>? fileBytes;
  final String mimeType;
  final bool isUploading;
  final double uploadProgress;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final bool isCompleted;

  bool get hasFile => fileBytes != null && fileBytes!.isNotEmpty;

  WorkerVerificationWizardState copyWith({
    int? currentStep,
    String? fullName,
    String? phoneNumber,
    String? selectedCooperativeId,
    List<CooperativeSociety>? societies,
    DocumentType? selectedDocType,
    String? fileName,
    List<int>? fileBytes,
    String? mimeType,
    bool? isUploading,
    double? uploadProgress,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool? isCompleted,
    bool clearFile = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return WorkerVerificationWizardState(
      currentStep: currentStep ?? this.currentStep,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      selectedCooperativeId: selectedCooperativeId ?? this.selectedCooperativeId,
      societies: societies ?? this.societies,
      selectedDocType: selectedDocType ?? this.selectedDocType,
      fileName: clearFile ? null : (fileName ?? this.fileName),
      fileBytes: clearFile ? null : (fileBytes ?? this.fileBytes),
      mimeType: mimeType ?? this.mimeType,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class WorkerVerificationWizardNotifier extends AutoDisposeNotifier<WorkerVerificationWizardState> {
  @override
  WorkerVerificationWizardState build() {
    final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
    String initialName = '';
    String initialPhone = '';

    final AppAuthState? auth = authAsync.value;
    if (auth is AuthAuthenticated) {
      initialName = auth.profile.fullName;
      initialPhone = auth.profile.phoneNumber;
    } else if (auth is AuthOnboardingRequired && auth.profile != null) {
      initialName = auth.profile!.fullName;
      initialPhone = auth.profile!.phoneNumber;
    }

    final WorkerVerificationWizardState stateObj = WorkerVerificationWizardState(
      fullName: initialName,
      phoneNumber: initialPhone,
    );

    Future<void>.microtask(loadSocieties);
    return stateObj;
  }

  Future<void> loadSocieties() async {
    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);
      final List<CooperativeSociety> societies = await repo.getCooperatives();
      state = state.copyWith(
        societies: societies,
        selectedCooperativeId: state.selectedCooperativeId ?? (societies.isNotEmpty ? societies.first.id : null),
      );
    } catch (_) {
      state = state.copyWith(societies: CooperativeSociety.fallbackSocieties);
    }
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void updateBasicInfo({
    required String fullName,
    required String phoneNumber,
    String? cooperativeId,
  }) {
    state = state.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      selectedCooperativeId: cooperativeId ?? state.selectedCooperativeId,
      clearError: true,
    );
  }

  void selectDocumentType(DocumentType docType) {
    state = state.copyWith(
      selectedDocType: docType,
      clearFile: true,
      clearError: true,
    );
  }

  void setDocumentFile({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) {
    state = state.copyWith(
      fileName: fileName,
      fileBytes: bytes,
      mimeType: mimeType,
      clearError: true,
    );
  }

  void simulateDocumentCapture() {
    final String typeName = state.selectedDocType.displayName;
    final String sampleData = '--- OFFICIAL VERIFICATION DOCUMENT ---\n'
        'Type: $typeName\n'
        'Owner: ${state.fullName.isNotEmpty ? state.fullName : "Worker"}\n'
        'Affiliation: Cooperative Federation of India\n'
        'Timestamp: ${DateTime.now().toIso8601String()}\n'
        'Status: Digitally Signed & Validated';
    final List<int> bytes = utf8.encode(sampleData);
    final String name = '${state.selectedDocType.dbValue}_verification.pdf';
    setDocumentFile(fileName: name, bytes: bytes, mimeType: 'application/pdf');
  }

  Future<bool> submitVerificationWizard() async {
    final AsyncValue<AppAuthState> authAsync = ref.read(authControllerProvider);
    final String userId = switch (authAsync.value) {
      AuthAuthenticated(:final UserProfile profile) => profile.id,
      AuthOnboardingRequired(:final sb.User user) => user.id,
      _ => 'worker-temp-${DateTime.now().millisecondsSinceEpoch}',
    };

    if (!state.hasFile) {
      state = state.copyWith(errorMessage: 'Please capture or select a verification document first.');
      return false;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.25,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final IWorkerRepository repo = ref.read(workerRepositoryProvider);

      state = state.copyWith(uploadProgress: 0.6);

      // 1. Upload to Supabase storage bucket 'worker-documents' & record metadata
      await repo.uploadDocument(
        workerId: userId,
        documentType: state.selectedDocType,
        fileName: state.fileName!,
        bytes: state.fileBytes!,
        mimeType: state.mimeType,
      );

      state = state.copyWith(uploadProgress: 0.85);

      // 2. Update worker profile to 'pending' (Under Review)
      final WorkerProfile currentProfile = await repo.getWorkerProfile(userId);
      final WorkerProfile updatedProfile = currentProfile.copyWith(
        fullName: state.fullName.isNotEmpty ? state.fullName : currentProfile.fullName,
        phoneNumber: state.phoneNumber.isNotEmpty ? state.phoneNumber : currentProfile.phoneNumber,
        cooperativeId: state.selectedCooperativeId ?? currentProfile.cooperativeId,
        verificationStatus: WorkerVerificationStatus.pending,
        rejectionReason: null,
        updatedAt: DateTime.now(),
      );

      await repo.updateWorkerProfile(updatedProfile);

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        isCompleted: true,
        successMessage: 'Documents uploaded to worker-documents bucket! Application submitted for review.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Verification submission failed: $e',
      );
      return false;
    }
  }
}

final AutoDisposeNotifierProvider<WorkerVerificationWizardNotifier, WorkerVerificationWizardState>
    workerVerificationWizardProvider =
    NotifierProvider.autoDispose<WorkerVerificationWizardNotifier, WorkerVerificationWizardState>(
  WorkerVerificationWizardNotifier.new,
);
