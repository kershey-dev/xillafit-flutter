import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/features/profile/data/profile_repository.dart';
import 'package:xillafit_flutter/features/profile/data/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(client: ref.watch(supabaseClientProvider));
});

/// Current user's profile row from `public.profiles`.
///
/// Returns `null` when:
/// - no auth session exists
/// - the profile row is missing (trigger didn’t create it)
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final session = ref.watch(authSessionProvider).asData?.value;
  final userId = session?.user.id;
  if (userId == null) return null;

  return ref.read(profileRepositoryProvider).getCurrentUserProfile();
});

