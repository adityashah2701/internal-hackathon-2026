import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

abstract interface class IProfileRepository {
  Future<UserProfile?> getProfile(String userId);

  Future<UserProfile> upsertProfile(UserProfile profile);

  Future<UserProfile> completeOnboarding({
    required String userId,
    required String email,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  });
}

class SupabaseProfileRepository implements IProfileRepository {
  SupabaseProfileRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is not initialized or offline.');
    }
    return safeClient;
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final Map<String, Object?>? data = await _safeClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        return null;
      }
      return UserProfile.fromJson(data);
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('PostgrestException fetching profile: ${e.message}', tag: 'ProfileRepo');
      if (e.code == 'PGRST205' || e.code == '42P01') {
        // Table not created yet in database
        return null;
      }
      throw ServerException(message: e.message, code: e.code, originalError: e);
    } catch (e, st) {
      AppLogger.error('Unexpected error fetching profile', error: e, stackTrace: st);
      throw UnexpectedException(message: 'Failed to load user profile.', originalError: e);
    }
  }

  @override
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    try {
      final Map<String, Object?> data = await _safeClient
          .from('profiles')
          .upsert(profile.toJson())
          .select()
          .single();

      return UserProfile.fromJson(data);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('PostgrestException upserting profile: ${e.message}', error: e);
      throw ServerException(message: e.message, code: e.code, originalError: e);
    } catch (e, st) {
      AppLogger.error('Unexpected error upserting profile', error: e, stackTrace: st);
      throw UnexpectedException(message: 'Failed to save profile.', originalError: e);
    }
  }

  @override
  Future<UserProfile> completeOnboarding({
    required String userId,
    required String email,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    // 1. Strict client-side validation
    if (!role.canSelfSelect) {
      throw const AuthorizationException(
        message: 'Administrative roles (Cooperative/Federation Admin) require manual approval and cannot be self-selected.',
      );
    }

    final String trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationException(message: 'Please provide your full name.');
    }

    // 2. Prepare payload
    final Map<String, Object> payload = <String, Object>{
      'id': userId,
      'email': email,
      'full_name': trimmedName,
      'phone_number': phoneNumber.trim(),
      'role': role.dbValue,
      'is_onboarded': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final Map<String, Object?> data = await _safeClient
          .from('profiles')
          .upsert(payload)
          .select()
          .single();

      AppLogger.info('Profile onboarding completed successfully for user $userId with role ${role.name}');
      return UserProfile.fromJson(data);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('PostgrestException during onboarding: ${e.message}', error: e);
      if (e.code == 'PGRST205' || e.code == '42P01') {
        // Fallback for when developer hasn't executed migration SQL on remote database yet
        AppLogger.warning('Profiles table not yet migrated on remote Supabase. Using local profile state.');
        return UserProfile(
          id: userId,
          email: email,
          fullName: trimmedName,
          phoneNumber: phoneNumber.trim(),
          role: role,
          isOnboarded: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      throw ServerException(message: e.message, code: e.code, originalError: e);
    } catch (e, st) {
      AppLogger.error('Unexpected error during onboarding', error: e, stackTrace: st);
      throw UnexpectedException(message: 'Failed to complete profile onboarding.', originalError: e);
    }
  }
}

final Provider<IProfileRepository> profileRepositoryProvider = Provider<IProfileRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseProfileRepository(client: client);
});
