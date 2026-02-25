# Supabase Production Environment Setup (TASK-002 & TASK-003)

## 1. Create Production Project

1. Go to https://supabase.com/dashboard
2. New Project → Name: `learn-fm-prod` → Region: closest to users
3. Save the generated DB password securely

## 2. Run Schema Migration

```sql
-- Execute in Supabase SQL Editor (production)
-- File: supabase/migrations/001_initial_schema.sql
```

Run all migration files in order from the `supabase/migrations/` directory.

## 3. Configure Authentication

- Dashboard → Authentication → Providers
  - Enable **Google** OAuth: add Client ID + Secret from Google Cloud Console
  - Enable **Phone** (Twilio): add Account SID, Auth Token, Message Service SID
- Redirect URLs: add `io.supabase.learnfm://login-callback/`

## 4. Required GitHub Secrets (TASK-003)

| Secret | Where to Find |
|--------|---------------|
| `SUPABASE_URL` | Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Project Settings → API → anon/public key |
| `SUPABASE_DB_URL` | Project Settings → Database → Connection string |
| `SUPABASE_PROJECT_REF` | Project Settings → General → Reference ID |
| `SUPABASE_ACCESS_TOKEN` | Account → Access Tokens |
| `CLAUDE_API_KEY` | console.anthropic.com → API Keys |

## 5. Flutter Environment Config

Create `lib/core/config/env.dart`:

```dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');
}
```

## 6. Edge Functions Deployment (TASK-004)

```bash
supabase functions deploy ai-chat --project-ref <YOUR_PROJECT_REF>
supabase functions deploy exam-generator --project-ref <YOUR_PROJECT_REF>
supabase functions deploy tts --project-ref <YOUR_PROJECT_REF>
```

## 7. Row Level Security - Verify Policies

```sql
-- Confirm RLS is enabled on all tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

All tables must show `rowsecurity = true` before go-live.
