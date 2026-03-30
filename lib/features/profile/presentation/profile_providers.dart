import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/auth/presentation/auth_providers.dart';
import 'package:xillafit_flutter/features/profile/data/profile_repository.dart';
import 'package:xillafit_flutter/features/profile/data/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Current user's profile row from `public.profiles`.
///
/// Returns `null` when:
/// - no auth session exists
/// - the profile row is missing (trigger didn’t create it)
final currentProfileProvider = FutureProvider.autoDispose<ProfileModel?>((ref) async {
  final session = ref.watch(authSessionProvider).asData?.value;
  final userId = session?.user.id;
  if (userId == null) return null;

  return ref.read(profileRepositoryProvider).getCurrentUserProfile();
});

