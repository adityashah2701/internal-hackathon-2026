class CooperativeSociety {
  const CooperativeSociety({
    required this.id,
    required this.name,
    required this.code,
    required this.district,
    required this.state,
    this.registrationNumber,
    this.contactEmail,
    this.contactPhone,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String district;
  final String state;
  final String? registrationNumber;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get locationFormatted => '$district, $state';

  factory CooperativeSociety.fromJson(Map<String, Object?> json) {
    return CooperativeSociety(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      registrationNumber: json['registration_number'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']! as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']! as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'code': code,
      'district': district,
      'state': state,
      'registration_number': registrationNumber,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
    };
  }

  /// Default seed societies for offline resilience and fast prototyping
  static const List<CooperativeSociety> fallbackSocieties = <CooperativeSociety>[
    CooperativeSociety(
      id: 'coop-pune-01',
      name: 'Shramik Kalyan Labour Cooperative Society',
      code: 'SKLCS-MH-01',
      district: 'Pune',
      state: 'Maharashtra',
      registrationNumber: 'MH/PUN/COOP/2021/8492',
      contactEmail: 'pune.kalyan@sahayog.coop',
      contactPhone: '+91 20 2567 8901',
    ),
    CooperativeSociety(
      id: 'coop-blr-02',
      name: 'Sahakar Nirman Workers Union',
      code: 'SNWU-KA-02',
      district: 'Bengaluru Urban',
      state: 'Karnataka',
      registrationNumber: 'KA/BLR/COOP/2020/5120',
      contactEmail: 'blr.nirman@sahayog.coop',
      contactPhone: '+91 80 2234 5678',
    ),
    CooperativeSociety(
      id: 'coop-del-03',
      name: 'Lokseva Artisan Cooperative Federation',
      code: 'LACF-DL-03',
      district: 'Central Delhi',
      state: 'Delhi',
      registrationNumber: 'DL/CEN/COOP/2019/3301',
      contactEmail: 'delhi.lokseva@sahayog.coop',
      contactPhone: '+91 11 2389 4455',
    ),
  ];
}
