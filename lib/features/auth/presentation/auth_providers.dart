import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Latest session from Supabase (restored on cold start + updates on auth changes).
final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  final initial = repo.currentSession;
  debugPrint(
    '[AUTH] authSessionProvider initial session: '
    '${initial == null ? 'none' : 'userId=${initial.user.id}'}',
  );
  yield initial;
  await for (final data in repo.onAuthStateChange) {
    debugPrint(
      '[AUTH] authStateChange event=${data.event.name}, '
      'session=${data.session == null ? 'none' : 'userId=${data.session!.user.id}'}',
    );
    yield data.session;
  }
});
