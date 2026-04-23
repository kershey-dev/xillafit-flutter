import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);

  final initial = await connectivity.checkConnectivity();
  yield _isOffline(initial);

  await for (final results in connectivity.onConnectivityChanged) {
    yield _isOffline(results);
  }
});

bool _isOffline(List<ConnectivityResult> results) {
  if (results.isEmpty) return true;
  return results.every((result) => result == ConnectivityResult.none);
}
