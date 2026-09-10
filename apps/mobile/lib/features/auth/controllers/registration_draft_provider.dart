import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_role.dart';

class RegistrationDraft {
  const RegistrationDraft({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.phoneNumber = '',
    this.role = UserRole.customer,
    this.preferredLanguage = 'English',
    this.address = 'Model Colony, Shivaji Nagar, Pune - 411016',
    this.houseFlatNumber = '',
    this.buildingName = '',
    this.landmark = '',
    this.latitude = 18.5204,
    this.longitude = 73.8567,
    this.trade = 'Electrician',
    this.experienceYears = 3,
    this.workerUpi = 'worker@okaxis',
    this.profilePhotoBytes,
  });

  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final UserRole role;
  final String preferredLanguage;
  final String address;
  final String houseFlatNumber;
  final String buildingName;
  final String landmark;
  final double latitude;
  final double longitude;
  final String trade;
  final int experienceYears;
  final String workerUpi;
  final Uint8List? profilePhotoBytes;

  RegistrationDraft copyWith({
    String? fullName,
    String? email,
    String? password,
    String? phoneNumber,
    UserRole? role,
    String? preferredLanguage,
    String? address,
    String? houseFlatNumber,
    String? buildingName,
    String? landmark,
    double? latitude,
    double? longitude,
    String? trade,
    int? experienceYears,
    String? workerUpi,
    Uint8List? profilePhotoBytes,
  }) {
    return RegistrationDraft(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      address: address ?? this.address,
      houseFlatNumber: houseFlatNumber ?? this.houseFlatNumber,
      buildingName: buildingName ?? this.buildingName,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      trade: trade ?? this.trade,
      experienceYears: experienceYears ?? this.experienceYears,
      workerUpi: workerUpi ?? this.workerUpi,
      profilePhotoBytes: profilePhotoBytes ?? this.profilePhotoBytes,
    );
  }
}

class RegistrationDraftNotifier extends Notifier<RegistrationDraft> {
  @override
  RegistrationDraft build() {
    return const RegistrationDraft();
  }

  void updateCredentials({
    required String fullName,
    required String email,
    required String password,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  void updateRole(UserRole role) {
    state = state.copyWith(role: role);
  }

  void updateCustomerDetails({
    required String phoneNumber,
    required String preferredLanguage,
    required String address,
    required String houseFlatNumber,
    required String buildingName,
    required String landmark,
    required double latitude,
    required double longitude,
    Uint8List? photoBytes,
  }) {
    state = state.copyWith(
      phoneNumber: phoneNumber,
      preferredLanguage: preferredLanguage,
      address: address,
      houseFlatNumber: houseFlatNumber,
      buildingName: buildingName,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      profilePhotoBytes: photoBytes ?? state.profilePhotoBytes,
    );
  }

  void updateWorkerDetails({
    required String phoneNumber,
    required String preferredLanguage,
    required String trade,
    required int experienceYears,
    required String coverageAreas,
    required String upiId,
    required String houseFlatNumber,
    required String buildingName,
    required String landmark,
    required double latitude,
    required double longitude,
    Uint8List? photoBytes,
  }) {
    state = state.copyWith(
      phoneNumber: phoneNumber,
      preferredLanguage: preferredLanguage,
      trade: trade,
      experienceYears: experienceYears,
      address: coverageAreas,
      workerUpi: upiId,
      houseFlatNumber: houseFlatNumber,
      buildingName: buildingName,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      profilePhotoBytes: photoBytes ?? state.profilePhotoBytes,
    );
  }

  void reset() {
    state = const RegistrationDraft();
  }
}

final NotifierProvider<RegistrationDraftNotifier, RegistrationDraft> registrationDraftProvider =
    NotifierProvider<RegistrationDraftNotifier, RegistrationDraft>(RegistrationDraftNotifier.new);
