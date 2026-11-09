# Hotel Guide app (Flutter) - Android + iOS

Native app for hotel guests. It opens the hotel's **Info Kiosk** page (mobile view) from your WordPress site,
so everything you edit in the plugin shows up in the app at once - no app update needed.

## How guests use it
1. Install the app, open it.
2. Type the hotel website (or paste the hotel link from **Info Kiosk > Settings > Hotel links**, the *mobile* link).
3. Pick the hotel (skipped when the link already names the hotel). Done - it remembers the choice.

Staff: press and hold the top-left corner of the app for 1.5 seconds to Reload or Change hotel.
Phone numbers, e-mail, maps, WhatsApp and other websites open in the matching phone app. Offline shows a "Try again" screen.

Needs plugin **Info Kiosk 1.5.8 or newer** (adds the light `/wp-json/infokiosk/v1/app/mobile` address the app reads).

## Build it - pick ONE way

### A) In the cloud, nothing to install (recommended)
1. Create a free GitHub repository and upload the contents of this folder.
2. GitHub > **Actions** > *Build apps* > **Run workflow**.
3. Download the artifacts: `android` (app-release.apk to install, app-release.aab for Google Play) and `ios-unsigned`.
4. iOS needs signing to run on iPhones: use `codemagic.yaml` with an Apple Developer account (99 USD/year) to publish to TestFlight / App Store.

### B) On your computer
Install Flutter (https://docs.flutter.dev/get-started/install), then in this folder:
- macOS / Linux: `./setup.sh`      Windows: `setup.bat`
- Android: `flutter build apk --release`  (file: build/app/outputs/flutter-apk/app-release.apk)
- iOS (needs a Mac + Xcode): `flutter build ipa`

## Change name, id, icon
- App name: `appName` in `tool/patch_platforms.dart`.
- Package / bundle id: `--org com.cbh` in the scripts (result: com.cbh.hotel_guide_app).
- Icon: replace `assets/icon.png` (1024x1024) and `assets/icon_foreground.png`, then `dart run flutter_launcher_icons`.

## Google Play / App Store notes
- Android Play uploads need your own signing key (https://docs.flutter.dev/deployment/android#signing-the-app).
- Apple may reject apps that are only a website wrapper (guideline 4.2). Keep the native parts (setup screen, hotel
  selection, offline screen, external-app handling) and describe the app as the hotel's guest services app.
