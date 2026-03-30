/// Compile-time Supabase configuration.
///
/// Prefer production builds with:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// Defaults match the web client’s public anon config in this monorepo (`XillFit/client`).
/// The anon key is intended to be public in client apps; still use `--dart-define`
/// or flavors if you need different projects per environment.
class SupabaseEnv {
  SupabaseEnv._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jepducibepowwddpahjb.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImplcGR1Y2liZXBvd3dkZHBhaGpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNjI5MzAsImV4cCI6MjA4NzkzODkzMH0.-shKfNQiTLOd7fzfYzcjl4mRg_gTIv5qFmOHAgePgCY',
  );

  /// Isolated from web `localStorage` keys so browser + app sessions don’t clash.
  static const String authStorageKey = 'sb-xillafit-flutter-auth';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
