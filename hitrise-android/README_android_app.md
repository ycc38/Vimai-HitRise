# HitRise Android

This folder contains a native Android app project for HitRise.

Implemented features:

- 3, 2, 1 countdown before training starts
- 30-second and 60-second training modes
- Live large-number hit counter
- Automatic post-session report:
  - total hit count
  - average frequency (hits per second)
  - best 3-second burst
- Microphone-based hit detection adapted from the tuned desktop Python version
- Bundled light-hit template based on `hit_template_light.npz`

Notes for opening/building:

- Open the `hitrise-android` folder in Android Studio.
- Let Android Studio sync the project and download the required Android/Gradle components.
- After sync, run the app on an Android phone and grant microphone permission.

Building from the command line:

- Requires JDK 17 and the Android SDK with `platforms;android-36` (point `ANDROID_HOME` or `sdk.dir` in `local.properties` at it). Gradle 8.13 comes from the checked-in wrapper.
- Debug APK: `gradlew.bat assembleDebug` on Windows, `./gradlew assembleDebug` elsewhere. Output: `app/build/outputs/apk/debug/app-debug.apk`. `gradlew.bat packageDebugApk` also copies it to `app/build/outputs/apk/distribution/HitRise.apk`.
- Google Play bundle: `gradlew.bat bundleRelease`. Output: `app/build/outputs/bundle/release/app-release.aab`.

Release signing (Google Play upload key):

The release build is signed only when `keystore.properties` exists in this folder. That file and the key (`*.jks`, `*.keystore`) are git-ignored and must never be committed. Without `keystore.properties`, debug builds work as usual and `bundleRelease` produces an unsigned bundle, which Play Console rejects.

1. Create the upload key once with `keytool` (part of the JDK; Android Studio ships it in `jbr/bin`). Keep the file outside the repository and back it up:

   ```
   keytool -genkeypair -v -keystore C:/keys/hitrise-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```

   keytool asks for the keystore password and the certificate details. Its default PKCS12 format uses the keystore password for the key too.

2. Create `keystore.properties` next to `settings.gradle.kts`:

   ```properties
   storeFile=C:/keys/hitrise-upload.jks
   storePassword=<keystore password>
   keyAlias=upload
   keyPassword=<keystore password>
   ```

   `storeFile` is absolute or relative to this folder. Write Windows paths with forward slashes; a single backslash is an escape character in `.properties` files.

3. Raise `versionCode` in `app/build.gradle.kts` for every upload, run `gradlew.bat bundleRelease`, and upload `app/build/outputs/bundle/release/app-release.aab`. Play App Signing keeps the app signing key at Google; this upload key only authenticates uploads, and a lost upload key can be reset from Play Console.
