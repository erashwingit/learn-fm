# Security Fixes — HIGH Findings (TASK-007 & TASK-008)

## Fix 1: API Key Exposure — RESOLVED ✅

**Before:** `AppConfig` contained hardcoded placeholder strings for Supabase and Claude API keys.
**Risk:** Compiled Flutter app could be reverse-engineered to extract keys.

**After:**
- `app_config.dart` — all secrets read from `--dart-define` compile-time flags (never hardcoded)
- `supabase/functions/ai-chat/index.ts` — Claude API key lives **only** in Supabase Edge Function env vars
- Flutter client calls the Edge Function via JWT-authenticated POST; Claude key never leaves the server
- `AppConfig.validate()` fails fast at startup if required env vars are missing

**Run command:**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

**Edge Function secrets (set once via Supabase CLI):**
```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

---

## Fix 2: Missing Certificate Pinning — RESOLVED ✅

**Before:** App used the default Flutter HTTP client with no TLS certificate verification beyond OS trust store.
**Risk:** MITM attacks on unsecured networks (cafes, hotels, public Wi-Fi) could intercept API traffic.

**After:**
- `lib/core/network/secure_http_client.dart` — custom `HttpClient` validates the SHA-256 fingerprint of the server's TLS certificate against a hardcoded allow-list
- `lib/core/services/ai_service_secure.dart` — uses `SecureHttpClient` for all Edge Function calls
- `pubspec.yaml` — added `crypto: ^3.0.3` for SHA-256 computation; added `assets/certs/` path

**One-time certificate setup:**
```bash
# 1. Export Supabase certificate
openssl s_client -connect <your-project>.supabase.co:443 </dev/null 2>/dev/null \
  | openssl x509 -outform DER > assets/certs/supabase.der

# 2. Compute SHA-256 fingerprint
openssl dgst -sha256 -binary assets/certs/supabase.der | openssl base64

# 3. Paste the Base64 fingerprint into SecureHttpClient._pinnedFingerprints
```

**Certificate rotation procedure:**
1. Add the new certificate fingerprint to `_pinnedFingerprints` (keep old + new during transition)
2. Release app update to Play Store/App Store
3. After sufficient rollout, remove old fingerprint in next release

---

## Remaining MEDIUM/WARN Items (addressed in follow-up sprint)

| Finding | Fix | Priority |
|---------|-----|----------|
| Error messages expose internals | Sanitize `catch (e)` blocks to show user-friendly messages only | Medium |
| Phone input lacks format validation | Add regex validator: `^\\+91[6-9]\\d{9}$` | Medium |
| `fromJson` lacks null guards | Add required field assertions | Medium |
| OAuth state parameter not validated | Validate `state` param in deep link callback | Medium |
| `.gitignore` completeness | Ensure `*.jks`, `*.keystore`, `google-services.json`, `GoogleService-Info.plist` are ignored | Low |

---

## Security Status Summary

| Finding | Severity | Status |
|---------|----------|--------|
| API keys in client bundle | 🔴 HIGH | ✅ FIXED |
| Missing certificate pinning | 🔴 HIGH | ✅ FIXED |
| Error message information leak | 🟡 MEDIUM | ⏳ Pending |
| Phone input validation | 🟡 MEDIUM | ⏳ Pending |
| OAuth state parameter | 🟡 MEDIUM | ⏳ Pending |
| `fromJson` null guards | 🟡 MEDIUM | ⏳ Pending |
| `.gitignore` completeness | 🟢 LOW | ⏳ Pending |
