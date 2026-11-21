/// Build-time configuration from `--dart-define-from-file=env.json`.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const appTimezone = String.fromEnvironment(
    'APP_TIMEZONE',
    defaultValue: 'Asia/Kolkata',
  );

  /// Demo mode runs entirely in memory when Supabase is not configured.
  static bool get isDemo => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
}
