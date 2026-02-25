/// AppConfig reads all sensitive values from compile-time --dart-define flags.
/// NEVER hardcode API keys or URLs here.
///
/// Build command:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
///
/// For CI/CD inject via GitHub Secrets (see cicd-pipeline.yml).
class AppConfig {
  // ─── Supabase (read from --dart-define, fall back to empty string) ─────────
  // The Supabase ANON key is safe to ship in the client — it is public by
  // design and all data access is protected by Row-Level Security policies.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // ─── Claude AI ─────────────────────────────────────────────────────────────
  // The Claude API key is NEVER in the client bundle.
  // All AI requests are proxied through the Supabase Edge Function
  // `supabase/functions/ai-chat/index.ts` which holds the key server-side.
  static const String aiEdgeFunctionUrl = '$supabaseUrl/functions/v1/ai-chat';

  // ─── App ───────────────────────────────────────────────────────────────────
  static const String appName = 'Learn Facility Management';
  static const String appVersion = '1.0.0';

  // ─── Rate Limiting ─────────────────────────────────────────────────────────
  static const int maxAiQueriesPerDay = 50;
  static const int maxAiQueriesPerHour = 10;

  // ─── Content ───────────────────────────────────────────────────────────────
  static const int maxChunkSize = 1000;
  static const int maxRetrievedChunks = 5;

  // ─── UI ────────────────────────────────────────────────────────────────────
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);

  // ─── i18n ──────────────────────────────────────────────────────────────────
  static const List<String> supportedLanguages = ['en', 'hi'];

  // ─── FM Domains ────────────────────────────────────────────────────────────
  static const List<Map<String, String>> domains = [
    {'id': '1',  'name': 'Technical Services',     'icon': 'technical'},
    {'id': '2',  'name': 'Housekeeping',            'icon': 'housekeeping'},
    {'id': '3',  'name': 'Security Management',     'icon': 'security'},
    {'id': '4',  'name': 'Fire and Safety',         'icon': 'fire_safety'},
    {'id': '5',  'name': 'Facade Cleaning',         'icon': 'facade'},
    {'id': '6',  'name': 'Pest Control',            'icon': 'pest_control'},
    {'id': '7',  'name': 'Helpdesk Functions',      'icon': 'helpdesk'},
    {'id': '8',  'name': 'Accounts Function',       'icon': 'accounts'},
    {'id': '9',  'name': 'Budgeting',               'icon': 'budgeting'},
    {'id': '10', 'name': 'Building Compliances',    'icon': 'building_compliance'},
    {'id': '11', 'name': 'Labour Compliances',      'icon': 'labour_compliance'},
    {'id': '12', 'name': 'Vendor Management',       'icon': 'vendor'},
    {'id': '13', 'name': 'Store Management',        'icon': 'store'},
    {'id': '14', 'name': 'Procurement',             'icon': 'procurement'},
  ];

  // ─── Validation ────────────────────────────────────────────────────────────
  /// Call this at app startup to fail fast if required config is missing.
  static void validate() {
    assert(
      supabaseUrl.isNotEmpty,
      'SUPABASE_URL is not set. Pass --dart-define=SUPABASE_URL=<value>',
    );
    assert(
      supabaseAnonKey.isNotEmpty,
      'SUPABASE_ANON_KEY is not set. Pass --dart-define=SUPABASE_ANON_KEY=<value>',
    );
  }
}
