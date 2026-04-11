import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/features/profile/data/profile_model.dart';

class ProfileRepository {
  ProfileRepository({required SupabaseClient client}) : _client = client;
  final SupabaseClient _client;

  /// Fetch the currently logged-in user's row from `public.profiles`.
  ///
  /// Returns `null` if the profile row is missing.
  Future<ProfileModel?> getCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select('''
          id,
          email,
          full_name,
          role,
          contact_number,
          address,
          account_status,
          created_at,
          avatar_url,
          customer_profiles (
            municipality,
            barangay,
            street_address,
            zip_code,
            province
          )
        ''')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ProfileModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  Future<void> updateProfile({
    required String fullName,
    String? contactNumber,
    String? address,
    String? municipality,
    String? barangay,
    String? streetAddress,
    String? zipCode,
    String? province,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not authenticated');
    }

    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'contact_number': (contactNumber ?? '').trim().isEmpty ? null : contactNumber!.trim(),
      'address': (address ?? '').trim().isEmpty ? null : address!.trim(),
    }).eq('id', userId);

    await _client.from('customer_profiles').upsert({
      'profile_id': userId,
      'municipality': (municipality ?? '').trim().isEmpty ? null : municipality!.trim(),
      'barangay': (barangay ?? '').trim().isEmpty ? null : barangay!.trim(),
      'street_address': (streetAddress ?? '').trim().isEmpty ? null : streetAddress!.trim(),
      'zip_code': (zipCode ?? '').trim().isEmpty ? null : zipCode!.trim(),
      'province': (province ?? '').trim().isEmpty ? 'Bulacan' : province!.trim(),
    }, onConflict: 'profile_id');

    await _client.auth.updateUser(
      UserAttributes(
        data: {'full_name': fullName.trim()},
      ),
    );
  }
}
