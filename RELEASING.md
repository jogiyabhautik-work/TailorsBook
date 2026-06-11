# Releasing TailorsBook

This guide outlines the process for releasing a new version of TailorsBook with the in-app update system.

## 1. Supabase Setup
Ensure your `in_app_updater` table is configured as follows in the public schema:

| Column Name | Type | Description |
|-------------|------|-------------|
| `latest_version` | `text` | e.g., '1.0.1' |
| `minimum_supported_version` | `text` | e.g., '1.0.0' |
| `update_required` | `bool` | Set to true for forced update |
| `flexible_allowed` | `bool` | Set to true for background download |
| `update_title` | `text` | Title for the update dialog |
| `update_description` | `text` | Changelog/description |
| `apk_url` | `text` | Direct link to download the APK |
| `apk_size_bytes` | `int8` | Size of APK in bytes |

**SQL to create table:**
```sql
CREATE TABLE IF NOT EXISTS public.in_app_updater (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    latest_version text NOT NULL,
    minimum_supported_version text NOT NULL,
    update_required boolean DEFAULT false,
    flexible_allowed boolean DEFAULT true,
    update_title text DEFAULT 'Update Available',
    update_description text DEFAULT '',
    apk_url text,
    apk_size_bytes bigint,
    updated_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.in_app_updater ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access" ON public.in_app_updater FOR SELECT USING (true);
```

## 2. Versioning
Before building, increment the version in `pubspec.yaml`:
- **Format:** `version: x.y.z+n`
- `x.y.z` is the semantic version (e.g., `1.0.1`).
- `+n` is the build number (e.g., `+2`). This **must** increase for every release.

## 3. Pre-Deployment Checklist
Run these commands in order to ensure a clean production build:

```bash
# 1. Clean build artifacts
flutter clean

# 2. Update dependencies
flutter pub get

# 3. (Optional) Run tests to ensure stability
flutter test

# 4. Generate build
flutter build apk --release
```

## 4. Deployment
1. Upload the generated APK (`build/app/outputs/flutter-apk/app-release.apk`) to your hosting/website.
2. Update the `in_app_updater` table in Supabase with the new version string and the link to the uploaded APK.
3. Users will now see the update prompt in their profile tab or upon app start (if implemented).

## 5. Security Note
- Never commit your `.env` file.
- Ensure your signing configuration (`key.properties`) is kept private and excluded from Git.

## 6. Android Signing Setup
To sign your app for release, create `android/key.properties` (do not commit this):
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/upload-keystore.jks
```
Then update `android/app/build.gradle.kts` to use these properties.
