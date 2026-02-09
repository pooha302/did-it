---
trigger: always_on
glob:
description: Guide for building and deploying the daily app to Google Play Store
---

# Play Store Build Guide

## 1. Versioning Rules
- **Version Name**: Managed in `pubspec.yaml`. (e.g., `1.2.1`)
- **Version Code**: Provided as a build option during the build process.

## 2. Signing Configuration
The app uses `android/key.properties` for signing.
- Keystore: `android/app/didit-keystore.jks`
- Key Alias: `didit`

## 3. API Keys
Firebase API keys are stored in `lib/config/api_keys.dart`.
This file is **EXCLUDED** from Git for security.
Make sure all keys are correctly restricted in the Google Cloud Console.

## 4. Build Command
To generate a release App Bundle with a specific version code (e.g., 11):
```bash
flutter build appbundle --release --build-number=11 --no-tree-shake-icons
```
*Note: The `--no-tree-shake-icons` flag is required because the app uses dynamic IconData.*
*Note: The version name will be automatically pulled from `pubspec.yaml`.*

## 5. Deployment & File Management
1. After the build completes, the `.aab` file is generated at:
   `build/app/outputs/bundle/release/app-release.aab`
2. **Rule**: Copy this file to your **Home Directory** for easy access before uploading:
   ```bash
   cp build/app/outputs/bundle/release/app-release.aab ~/app-release-11.aab
   ```
3. Upload the file to the Google Play Console.
