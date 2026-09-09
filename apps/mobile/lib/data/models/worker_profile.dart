enum WorkerVerificationStatus {
  unsubmitted('unsubmitted', 'Action Required', 'KYC & Skill verification required to receive jobs.'),
  pending('pending', 'Under Review', 'Your verification documents are being reviewed by your Cooperative Society.'),
  approved('approved', 'Verified Worker', 'Identity and trade qualifications verified by Cooperative Society.'),
  rejected('rejected', 'Changes Needed', 'Application was not approved. Please see the rejection reason below and resubmit.');

  const WorkerVerificationStatus(this.dbValue, this.displayName, this.description);

  final String dbValue;
  final String displayName;
  final String description;

  bool get isApproved => this == WorkerVerificationStatus.approved;
  bool get isPending => this == WorkerVerificationStatus.pending;
  bool get isRejected => this == WorkerVerificationStatus.rejected;
  bool get isUnsubmitted => this == WorkerVerificationStatus.unsubmitted;

  static WorkerVerificationStatus fromDbValue(String? value) {
    for (final WorkerVerificationStatus status in WorkerVerificationStatus.values) {
      if (status.dbValue == value) {
        return status;
      }
    }
    return WorkerVerificationStatus.unsubmitted;
  }
}

class WorkerProfile {
  const WorkerProfile({
    required this.id,
    this.cooperativeId,
    this.cooperativeName,
    this.skills = const <String>[],
    this.experienceYears = 0,
    this.dailyRateInr = 500,
    this.hourlyRateInr = 150,
    this.isAvailable = true,
    this.serviceArea = '',
    this.bio = '',
    this.verificationStatus = WorkerVerificationStatus.unsubmitted,
    this.rejectionReason,
    this.verifiedAt,
    this.verifiedBy,
    this.createdAt,
    this.updatedAt,
    this.fullName,
    this.phoneNumber,
    this.email,
  });

  final String id;
  final String? cooperativeId;
  final String? cooperativeName;
  final List<String> skills;
  final int experienceYears;
  final int dailyRateInr;
  final int hourlyRateInr;
  final bool isAvailable;
  final String serviceArea;
  final String bio;
  final WorkerVerificationStatus verificationStatus;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined user profile fields
  final String? fullName;
  final String? phoneNumber;
  final String? email;

  String get displayName => fullName != null && fullName!.isNotEmpty ? fullName! : 'Worker';

  WorkerProfile copyWith({
    String? id,
    String? cooperativeId,
    String? cooperativeName,
    List<String>? skills,
    int? experienceYears,
    int? dailyRateInr,
    int? hourlyRateInr,
    bool? isAvailable,
    String? serviceArea,
    String? bio,
    WorkerVerificationStatus? verificationStatus,
    String? rejectionReason,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fullName,
    String? phoneNumber,
    String? email,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      cooperativeName: cooperativeName ?? this.cooperativeName,
      skills: skills ?? this.skills,
      experienceYears: experienceYears ?? this.experienceYears,
      dailyRateInr: dailyRateInr ?? this.dailyRateInr,
      hourlyRateInr: hourlyRateInr ?? this.hourlyRateInr,
      isAvailable: isAvailable ?? this.isAvailable,
      serviceArea: serviceArea ?? this.serviceArea,
      bio: bio ?? this.bio,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }

  factory WorkerProfile.fromJson(Map<String, Object?> json) {
    final Object? rawSkills = json['skills'];
    final List<String> parsedSkills = <String>[];
    if (rawSkills is List) {
      for (final Object? item in rawSkills) {
        if (item is String) {
          parsedSkills.add(item);
        }
      }
    }

    // Handle join with profiles or cooperatives if present
    String? joinedName;
    String? joinedPhone;
    String? joinedEmail;
    String? joinedCoopName;

    if (json['profiles'] is Map) {
      final Map<String, Object?> profileMap = json['profiles']! as Map<String, Object?>;
      joinedName = profileMap['full_name'] as String?;
      joinedPhone = profileMap['phone_number'] as String?;
      joinedEmail = profileMap['email'] as String?;
    } else {
      joinedName = json['full_name'] as String?;
      joinedPhone = json['phone_number'] as String?;
      joinedEmail = json['email'] as String?;
    }

    if (json['cooperatives'] is Map) {
      final Map<String, Object?> coopMap = json['cooperatives']! as Map<String, Object?>;
      joinedCoopName = coopMap['name'] as String?;
    } else {
      joinedCoopName = json['cooperative_name'] as String?;
    }

    return WorkerProfile(
      id: json['id'] as String? ?? '',
      cooperativeId: json['cooperative_id'] as String?,
      cooperativeName: joinedCoopName,
      skills: parsedSkills,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      dailyRateInr: (json['daily_rate_inr'] as num?)?.toInt() ?? 500,
      hourlyRateInr: (json['hourly_rate_inr'] as num?)?.toInt() ?? 150,
      isAvailable: json['is_available'] as bool? ?? true,
      serviceArea: json['service_area'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      verificationStatus: WorkerVerificationStatus.fromDbValue(json['verification_status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at']! as String) : null,
      verifiedBy: json['verified_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']! as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']! as String) : null,
      fullName: joinedName,
      phoneNumber: joinedPhone,
      email: joinedEmail,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'cooperative_id': cooperativeId,
      'skills': skills,
      'experience_years': experienceYears,
      'daily_rate_inr': dailyRateInr,
      'hourly_rate_inr': hourlyRateInr,
      'is_available': isAvailable,
      'service_area': serviceArea,
      'bio': bio,
      'verification_status': verificationStatus.dbValue,
      'rejection_reason': rejectionReason,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
