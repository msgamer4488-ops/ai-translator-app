# AI Language Translator Pro — Android (Flutter)

This is a Flutter port of the Python/Tkinter desktop app. Tkinter can't run
on Android, so every OS-level feature (OCR, TTS, STT, file save) has been
swapped for an Android-native equivalent — see the mapping table below.

## What's included
```
lib/
  main.dart                 - app entry point, theme switching
  models/history_entry.dart - history record shape (matches the old JSON)
  services/
    translation_service.dart  - chunked translation (Google Translate)
    ocr_service.dart          - on-device OCR via ML Kit
    tts_service.dart          - text-to-speech via device voices
    stt_service.dart          - speech-to-text via device recognizer
    history_service.dart      - persisted translation history
    settings_service.dart     - persisted app settings
    file_service.dart         - open .txt, save as .txt/.pdf + share
  screens/
    home_screen.dart      - main translator UI
    history_screen.dart   - browse/reload past translations
    settings_screen.dart  - theme, chunk size, STT locale
  theme/app_theme.dart    - light/dark Material theme
```

## Feature mapping vs. the Python app

| Desktop (Python/Tkinter) | Android (this project) |
|---|---|
| deep_translator (Google Translate) | Same unofficial endpoint via `http` — swap for the paid Cloud Translation API for production reliability/quota |
| pytesseract + Tesseract binary | `google_mlkit_text_recognition` — on-device, no install/path setup |
| pyttsx3 / gTTS + pygame | `flutter_tts` — uses the phone's built-in voices |
| SpeechRecognition + pyaudio | `speech_to_text` — uses the phone's native recognizer |
| translator_config.json | `shared_preferences` (`settings_service.dart`) |
| translator_history.json | `shared_preferences` (`history_service.dart`) |
| Save TXT / DOCX / PDF | Save TXT / PDF + Android share sheet. DOCX export isn't included — add a docx-writing package if you need it |
| Drag & drop file onto window | Not a mobile pattern — replaced by the "Open .txt" file picker button |
| Batch translate multiple files | Not included in this scaffold — the per-file loop in `translate_text_chunks`/`batch_translate_worker` from the Python app can be reproduced by looping `TranslationService.translate` over picked files if you want it back |

## Getting an APK via GitHub Actions (no local install needed)

This project includes `.github/workflows/build.yml`, which builds a
release APK automatically — it handles `flutter create`, permissions,
and `minSdkVersion` for you.

1. Create a new **public or private** GitHub repo.
2. Push this whole folder to it:
   ```bash
   cd android_translator_app
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-repo>.git
   git push -u origin main
   ```
3. On GitHub, open the **Actions** tab. The "Build Android APK" workflow
   runs automatically on push (or click **Run workflow** to trigger it
   manually).
4. When it finishes (a few minutes), open the completed run and download
   the **app-release-apk** artifact from the bottom of the page — that
   zip contains `app-release.apk`.
5. Transfer the APK to your Android phone (email it to yourself, Google
   Drive, USB, etc.) and tap it to install. You'll need to allow
   "install from unknown sources" the first time, since it isn't signed
   for the Play Store.

This gives you an unsigned debug-style release APK for testing on your
own device. For an actual Play Store release you'd add a signing config
and app icon/name — ask if you want that added to the workflow too.

## Setup (building locally instead)

You need the Flutter SDK installed locally (this environment can't run
`flutter` itself). Steps:

1. **Scaffold the native Android/iOS shell** (this project only has `lib/`
   and `pubspec.yaml` — Flutter needs to generate the platform folders):
   ```bash
   cd android_translator_app
   flutter create . --platforms=android --org com.yourcompany
   ```
   This will create `android/`, plus a starter `lib/main.dart` — say yes
   to overwrite, since the real one is already here.

2. **Add permissions**: open `android/app/src/main/AndroidManifest.xml`
   and add the lines from `android_manifest_additions.xml` (included here)
   inside the `<manifest>` tag.

3. **Set minSdkVersion**: in `android/app/build.gradle`, ML Kit and
   speech_to_text need `minSdkVersion 21` or higher — set it if it's lower.

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Run on a connected device/emulator**:
   ```bash
   flutter run
   ```

6. **Build a release APK**:
   ```bash
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Notes / next steps
- The translation endpoint is the same unofficial one the Python app used
  via `deep_translator` — fine for personal use, but Google can rate-limit
  or change it without notice. For a Play Store release, get an API key
  for the official Cloud Translation API and swap the body of
  `TranslationService._translateChunk`.
- PDF/DOCX **input** (extracting text from an uploaded PDF/Word file, like
  the desktop app's `extract_text_from_file`) isn't wired up — only `.txt`
  input is supported out of the box, plus OCR for images. Add
  `syncfusion_flutter_pdf` (PDF) or a docx-parsing package if you need
  that back.
- First run will prompt for microphone/camera permissions at the point
  they're used (STT / OCR camera), per Android's runtime permission model.
