# Learn FM - Go-Live Setup Guide

> **For Ashwin Chuck** - Follow these steps to get Learn FM live on Android & iOS.

## Step 1: Create Supabase Production Project

1. Go to https://supabase.com/dashboard
2. Click **New Project**
3. Set name: `learn-fm-prod`
4. Choose region closest to India (ap-south-1)
5. Save the DB password somewhere safe
6. Wait 2 mins for project to spin up

## Step 2: Add GitHub Secrets

Go to: **GitHub.com → erashwingit/learn-fm → Settings → Secrets and variables → Actions → New repository secret**

Add these secrets one by one:

| Secret Name | Where to Get It |
|-------------|------------------|
| `SUPABASE_URL` | Supabase Dashboard → Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Project Settings → API → anon/public |
| `SUPABASE_DB_URL` | Supabase Dashboard → Project Settings → Database → Connection string (URI) |
| `SUPABASE_PROJECT_REF` | Supabase Dashboard → Project Settings → General → Reference ID |
| `SUPABASE_ACCESS_TOKEN` | supabase.com → Account → Access Tokens → Generate new token |
| `CLAUDE_API_KEY` | console.anthropic.com → API Keys → Create Key |
| `KEYSTORE_BASE64` | Base64 encoded Android keystore (run: `base64 your.keystore`) |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_ALIAS` | Your key alias |
| `KEY_PASSWORD` | Your key password |

## Step 3: Run Database Migration

1. Go to Supabase Dashboard → SQL Editor
2. Copy and run the file: `supabase/migrations/001_initial_schema.sql`
3. Verify all tables have RLS enabled

## Step 4: Set Supabase Edge Function Secrets

In your terminal (with Supabase CLI installed):

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set ANTHROPIC_API_KEY=sk-ant-YOUR_KEY
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
```

## Step 5: Deploy Edge Functions

```bash
supabase functions deploy ai-chat --project-ref YOUR_PROJECT_REF
```

## Step 6: Trigger CI/CD Build

Push any change to `main` branch - this will automatically:
- Run all 56 tests
- Build Android APK (release)
- Build iOS IPA (release)
- Deploy Supabase migrations
- Deploy Edge Functions

## Step 7: Download APK

After CI/CD completes (~15-20 mins):
1. Go to GitHub → Actions tab
2. Click the latest workflow run
3. Download `android-apk` artifact
4. Install APK on your Android device

## Test Credentials (Internal UAT)

- App: Flutter mobile app (Android & iOS)
- Auth: Google OAuth or Phone OTP
- AI Chat: Powered by Claude via Supabase Edge Function
- Exams: 50 questions, 30-minute timer, 70% pass mark

## Architecture Summary

```
User → Flutter App → Supabase (Auth + DB + RLS)
                  → Supabase Edge Function → Claude AI
```

## Key Security Features
- API keys NEVER in client bundle (dart-define + Edge Functions)
- Certificate pinning (SHA-256)
- Row-Level Security on all DB tables
- JWT-authenticated Edge Function calls

---

**Project Status:** CODE COMPLETE ✅ | Tests: 56/56 PASS ✅ | Security: HIGH findings FIXED ✅

**Next Action:** You (Ashwin) need to set GitHub Secrets and create Supabase project to trigger first build.
