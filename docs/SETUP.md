# Setup: Supabase, Google, and release builds

Pendi runs in demo mode until `env.json` provides Supabase keys. Copy `env.example.json` to `env.json` (git-ignored) and fill it in as you go.

| Key | Where it comes from | Needed for |
| --- | --- | --- |
| `SUPABASE_URL` | Supabase → Project Settings → API → Project URL | Sync, auth |
| `SUPABASE_ANON_KEY` | Supabase → Project Settings → API → publishable / anon key | Sync, auth |
| `GOOGLE_WEB_CLIENT_ID` | Google Cloud → Credentials → OAuth client (Web application) | Google sign-in on Android (server client ID) and Supabase |
| `APP_TIMEZONE` | IANA name, default `Asia/Kolkata` | Default "today" before the profile loads |

Never commit `env.json` or any secret.

## 1. Supabase project

1. Create a project at supabase.com (free tier is enough).
2. Open **SQL Editor**, paste `supabase/migrations/0001_init.sql`, and run it. It creates every table with row-level security so each user only sees their own rows. (Or with the CLI: `supabase link` then `supabase db push`.)
3. Copy the Project URL and the publishable (anon) key into `env.json`.

## 2. Google sign-in with Calendar access

1. In Google Cloud Console, create (or pick) a project and enable the **Google Calendar API**.
2. **OAuth consent screen**: External, add your Gmail as a test user, and add the scope `https://www.googleapis.com/auth/calendar`.
3. **Credentials → Create OAuth client ID**:
   - **Web application**: this is `GOOGLE_WEB_CLIENT_ID`. Add your Supabase callback `https://<project>.supabase.co/auth/v1/callback` as an authorized redirect URI.
   - **Android**: package name `dev.pendi.pendi`, plus the SHA-1 of your signing key. Debug key: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`. Add a second Android client later for the release key's SHA-1.
4. In Supabase → **Authentication → Providers → Google**: enable it, paste the Web client ID and secret, and add the Android client ID to "Authorized Client IDs" so `signInWithIdToken` accepts tokens from the app.

## 3. Run against your backend

```
flutter run --dart-define-from-file=env.json
```

Sign in with Google, then set your Codeforces handle in Settings (gear icon on Today) and tap **Sync from Codeforces** on the CP tab.

## 4. Release APK

1. Create a keystore: `keytool -genkey -v -keystore ~/pendi-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pendi`.
2. Create `android/key.properties` (git-ignored) with `storePassword`, `keyPassword`, `keyAlias=pendi`, `storeFile=/home/<you>/pendi-release.jks`, and wire it into `android/app/build.gradle.kts` `signingConfigs` (see flutter.dev/deployment/android).
3. Add the release SHA-1 as another Android OAuth client (step 2.3).
4. Build: `flutter build apk --release --dart-define-from-file=env.json` → `build/app/outputs/flutter-apk/app-release.apk`.

## Notes

- Calendar and Codeforces sync run when Today opens and on pull-to-refresh; there is no server cron.
- The link extractor fetches pages directly, which works on Android. In the web build most sites block cross-origin requests, so a link falls back to a single page.
