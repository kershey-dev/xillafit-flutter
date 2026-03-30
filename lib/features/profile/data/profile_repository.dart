import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/features/profile/data/profile_model.dart';

class ProfileRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Fetch the currently logged-in user's row from `public.profiles`.
  ///
  /// Returns `null` if the profile row is missing.
  Future<ProfileModel?> getCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select('id,email,full_name,role,contact_number,address,account_status,created_at,avatar_url')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ProfileModel.fromMap(Map<String, dynamic>.from(response as Map));
  }
}

