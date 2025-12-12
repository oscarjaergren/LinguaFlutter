# Android Beta Release Pipeline

This document describes how to set up the automated beta release pipeline for the Google Play Store.

## Overview

When code is pushed to the `main` branch, the pipeline automatically:
1. Runs tests
2. Builds a signed Android App Bundle (AAB)
3. Uploads to Google Play Store's **beta** track

## Prerequisites

### 1. Google Play Console Setup

1. **Create your app** in [Google Play Console](https://play.google.com/console)
2. **Complete the app setup checklist** (store listing, content rating, etc.)
3. **Upload your first AAB manually** - Google requires at least one manual upload before API access works

### 2. Create a Service Account

1. Go to **Google Play Console** → **Setup** → **API access**
2. Click **Create new service account**
3. Follow the link to **Google Cloud Console**
4. Create a service account with a descriptive name (e.g., `github-actions-deploy`)
5. Grant the role: **Service Account User**
6. Create a JSON key and download it
7. Back in Play Console, grant the service account **Release manager** permissions

### 3. Create an Upload Keystore

If you don't have one already:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important:** Store this keystore securely. If lost, you cannot update your app.

### 4. Configure GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

| Secret Name | Description |
|-------------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password (often same as keystore password) |
| `ANDROID_KEY_ALIAS` | Key alias (e.g., `upload`) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Full contents of the service account JSON file |

#### Encoding the Keystore

```bash
# On Linux/macOS
base64 -i upload-keystore.jks | tr -d '\n'

# On Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

## Workflow File

The workflow is defined in `.github/workflows/android-beta-release.yml`.

### Key Features

- **Triggered on push to main** - Every merge to main creates a beta release
- **Runs tests first** - Fails fast if tests don't pass
- **Signed builds** - Uses your upload keystore for signing
- **Artifacts retained** - AAB files are kept for 30 days

## Version Management

The version is controlled in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

- `1.0.0` = Version name (shown to users)
- `+1` = Version code (must increment for each upload)

**Important:** You must increment the version code (`+1`) before each release, or the Play Store will reject the upload.

### Auto-incrementing Version Code

For automatic version code incrementing, you can modify the workflow to use the GitHub run number:

```yaml
- name: Build App Bundle
  run: flutter build appbundle --release --build-number=${{ github.run_number }}
```

## Promoting to Production

Beta releases are not automatically promoted to production. To promote:

1. Go to **Google Play Console** → **Release** → **Testing** → **Open testing** (or Closed testing)
2. Review the beta release
3. Click **Promote release** → **Production**

## Troubleshooting

### "Package name not found"
- Ensure you've uploaded at least one AAB manually first
- Verify the package name matches: `com.linguaflutter.lingua_flutter`

### "Invalid credentials"
- Regenerate the service account JSON key
- Ensure the service account has **Release manager** permissions in Play Console

### "Version code already exists"
- Increment the version code in `pubspec.yaml`
- Or use auto-incrementing with `--build-number=${{ github.run_number }}`

### Build signing fails
- Verify the base64 encoding of your keystore is correct
- Check that all four signing secrets are set correctly
- Ensure the key alias matches what's in your keystore

## Local Testing

To test the signing configuration locally:

1. Create `android/key.properties`:
   ```properties
   storePassword=your_password
   keyPassword=your_key_password
   keyAlias=upload
   storeFile=path/to/upload-keystore.jks
   ```

2. Build the release:
   ```bash
   flutter build appbundle --release
   ```

**Never commit `key.properties` or keystore files to git.**
