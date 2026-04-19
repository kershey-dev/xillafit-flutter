import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';

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
    String? fullName,
    required String municipality,
    required String barangay,
    required String streetAddress,
    required String zipCode,
  }) async {
    final normalizedEmail = email.trim();
    final trimmedFullName = fullName?.trim();
    final trimmedMunicipality = municipality.trim();
    final trimmedBarangay = barangay.trim();
    final trimmedStreetAddress = streetAddress.trim();
    final trimmedZipCode = zipCode.trim();
    debugPrint('[AUTH] signUpWithEmail() attempt: email=$normalizedEmail');
    final response = await _client.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {
        if ((trimmedFullName ?? '').isNotEmpty) 'full_name': trimmedFullName,
        'municipality': trimmedMunicipality,
        'barangay': trimmedBarangay,
        'street_address': trimmedStreetAddress,
        'zip_code': trimmedZipCode,
        'province': 'Bulacan',
      },
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

  Future<bool> signInWithGoogle() async {
    debugPrint('[AUTH] signInWithGoogle() launch');
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      // Use the same mobile auth callback shape that the app bridge and
      // link handler already understand for web-to-app session handoff.
      redirectTo: kIsWeb ? null : AppLinks.authCallbackUrl(),
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    debugPrint('[AUTH] signInWithGoogle() launched=$launched');
    return launched;
  }
}
