/// Dart model for the `service_categories` table.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    this.iconName = 'build_rounded',
    this.description = '',
    this.isActive = true,
    this.sortOrder = 0,
    this.services = const <Service>[],
    this.createdAt,
  });

  final String id;
  final String name;
  final String iconName;
  final String description;
  final bool isActive;
  final int sortOrder;
  final List<Service> services;
  final DateTime? createdAt;

  /// Base price derived from the lowest-priced service in this category.
  int get basePrice {
    if (services.isEmpty) return 0;
    return services
        .map((Service s) => s.basePriceInr)
        .reduce((int a, int b) => a < b ? a : b);
  }

  factory ServiceCategory.fromJson(Map<String, Object?> json) {
    final List<Service> parsedServices = <Service>[];
    final Object? rawServices = json['services'];
    if (rawServices is List) {
      for (final Object? item in rawServices) {
        if (item is Map<String, Object?>) {
          parsedServices.add(Service.fromJson(item));
        }
      }
    }

    return ServiceCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? 'build_rounded',
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      services: parsedServices,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']! as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'icon_name': iconName,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  @override
  String toString() => 'ServiceCategory(id: $id, name: $name, services: ${services.length})';
}

/// Dart model for the `services` table.
class Service {
  const Service({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.basePriceInr = 300,
    this.requiredSkills = const <String>[],
    this.estimatedDurationMinutes = 60,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int basePriceInr;
  final List<String> requiredSkills;
  final int estimatedDurationMinutes;
  final bool isActive;
  final DateTime? createdAt;

  factory Service.fromJson(Map<String, Object?> json) {
    final Object? rawSkills = json['required_skills'];
    final List<String> parsedSkills = <String>[];
    if (rawSkills is List) {
      for (final Object? item in rawSkills) {
        if (item is String) {
          parsedSkills.add(item);
        }
      }
    }

    return Service(
      id: json['id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePriceInr: (json['base_price_inr'] as num?)?.toInt() ?? 300,
      requiredSkills: parsedSkills,
      estimatedDurationMinutes: (json['estimated_duration_minutes'] as num?)?.toInt() ?? 60,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']! as String)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'base_price_inr': basePriceInr,
      'required_skills': requiredSkills,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'Service(id: $id, name: $name, price: $basePriceInr)';
}
