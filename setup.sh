#!/usr/bin/env bash
# One-time project setup (macOS / Linux). Needs Flutter: https://docs.flutter.dev/get-started/install
set -e
flutter create --org com.cbh --project-name hotel_guide_app --platforms=android,ios .
flutter pub get
dart run tool/patch_platforms.dart
dart run flutter_launcher_icons
echo "Done. Run:  flutter run   |  flutter build apk --release   |  flutter build ipa"
