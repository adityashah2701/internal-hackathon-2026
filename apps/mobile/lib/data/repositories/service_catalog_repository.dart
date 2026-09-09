import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/service_category.dart';

/// Repository for loading service categories and services from Supabase.
///
/// Replaces the hardcoded [ServiceCategoryItem] list that was previously
/// embedded in the customer booking controller.
abstract interface class IServiceCatalogRepository {
  /// Fetches all active service categories with their services.
  Future<List<ServiceCategory>> getCategories();

  /// Fetches services for a specific category.
  Future<List<Service>> getServicesByCategory(String categoryId);
}

class SupabaseServiceCatalogRepository implements IServiceCatalogRepository {
  SupabaseServiceCatalogRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is offline or unconfigured.');
    }
    return safeClient;
  }

  @override
  Future<List<ServiceCategory>> getCategories() async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('service_categories')
          .select('*, services(*)')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response.map(ServiceCategory.fromJson).toList();
    } catch (e, st) {
      AppLogger.error('Error loading service categories', error: e, stackTrace: st);
      return const <ServiceCategory>[];
    }
  }

  @override
  Future<List<Service>> getServicesByCategory(String categoryId) async {
    try {
      final List<Map<String, Object?>> response = await _safeClient
          .from('services')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('name', ascending: true);

      return response.map(Service.fromJson).toList();
    } catch (e, st) {
      AppLogger.error('Error loading services for category $categoryId', error: e, stackTrace: st);
      return const <Service>[];
    }
  }
}

final Provider<IServiceCatalogRepository> serviceCatalogRepositoryProvider =
    Provider<IServiceCatalogRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseServiceCatalogRepository(client: client);
});
