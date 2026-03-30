import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth only — no REST proxy. Profile rows are created by DB triggers on signup.
class AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    debugPrint('[AUTH] signInWithEmail() attempt: email=$normalizedEmail');
    final response = await _client.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );
    debugPrint(
      '[AUTH] signInWithEmail() success: '
      'hasSession=${response.session != null}, userId=${response.user?.id}',
    );
    return response;
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    debugPrint('[AUTH] signUpWithEmail() attempt: email=$normalizedEmail');
    final response = await _client.auth.signUp(
      email: normalizedEmail,
      password: password,
    );
    debugPrint(
      '[AUTH] signUpWithEmail() response: '
      'hasSession=${response.session != null}, userId=${response.user?.id}',
    );
    return response;
  }

  Future<void> signOut() async {
    debugPrint('[AUTH] signOut()');
    await _client.auth.signOut();
  }
}
