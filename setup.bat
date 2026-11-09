@echo off
REM One-time project setup (Windows). Needs Flutter: https://docs.flutter.dev/get-started/install
call flutter create --org com.cbh --project-name hotel_guide_app --platforms=android,ios .
call flutter pub get
call dart run tool/patch_platforms.dart
call dart run flutter_launcher_icons
echo Done. Run:  flutter run   ^|  flutter build apk --release
