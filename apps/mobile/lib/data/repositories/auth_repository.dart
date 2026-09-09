import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/network/supabase_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_role.dart';

abstract interface class IAuthRepository {
  sb.User? get currentUser;
  sb.Session? get currentSession;
  Stream<sb.AuthState> get onAuthStateChange;

  Future<sb.AuthResponse> signInWithEmail({
    required String email,
    required String password,
  });

  Future<sb.AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    UserRole? role,
  });

  Future<void> signOut();
}

class SupabaseAuthRepository implements IAuthRepository {
  SupabaseAuthRepository({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _safeClient {
    final sb.SupabaseClient? safeClient = client ?? SupabaseClientManager.client;
    if (safeClient == null) {
      throw const NetworkException(message: 'Supabase client is not initialized or offline.');
    }
    return safeClient;
  }

  @override
  sb.User? get currentUser => client?.auth.currentUser;

  @override
  sb.Session? get currentSession => client?.auth.currentSession;

  @override
  Stream<sb.AuthState> get onAuthStateChange =>
      client?.auth.onAuthStateChange ?? const Stream<sb.AuthState>.empty();

  @override
  Future<sb.AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final sb.AuthResponse response = await _safeClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('User signed in successfully: ${response.user?.id}');
      return response;
    } on sb.AuthException catch (e) {
      AppLogger.error('AuthException during sign in', error: e);
      throw AuthException(message: e.message, code: e.statusCode);
    } catch (e, st) {
      AppLogger.error('Unexpected error during sign in', error: e, stackTrace: st);
      throw UnexpectedException(message: 'Failed to sign in. Please try again.', originalError: e);
    }
  }

  @override
  Future<sb.AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    UserRole? role,
  }) async {
    try {
      final Map<String, Object> data = <String, Object>{};
      if (fullName != null && fullName.isNotEmpty) {
        data['full_name'] = fullName;
      }
      if (role != null && role.canSelfSelect) {
        data['role'] = role.dbValue;
      }

      final sb.AuthResponse response = await _safeClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: data.isNotEmpty ? data : null,
      );
      AppLogger.info('User signed up successfully: ${response.user?.id}');
      return response;
    } on sb.AuthException catch (e) {
      AppLogger.error('AuthException during sign up', error: e);
      throw AuthException(message: e.message, code: e.statusCode);
    } catch (e, st) {
      AppLogger.error('Unexpected error during sign up', error: e, stackTrace: st);
      throw UnexpectedException(message: 'Failed to sign up. Please try again.', originalError: e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _safeClient.auth.signOut();
      AppLogger.info('User signed out.');
    } on sb.AuthException catch (e) {
      AppLogger.error('AuthException during sign out', error: e);
      throw AuthException(message: e.message, code: e.statusCode);
    } catch (e, st) {
      AppLogger.error('Unexpected error during sign out', error: e, stackTrace: st);
      throw UnexpectedException(message: 'Failed to sign out.', originalError: e);
    }
  }
}

final Provider<IAuthRepository> authRepositoryProvider = Provider<IAuthRepository>((Ref ref) {
  final sb.SupabaseClient? client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client: client);
});
