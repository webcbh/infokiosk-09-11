// Run once after `flutter create`:  dart run tool/patch_platforms.dart
// Adds what the generated Android / iOS projects are missing for this app
// (internet access, phone / mail / maps links, app name).
import 'dart:io';

const appName = 'Hotel Guide';

void main() {
  _android();
  _ios();
  stdout.writeln('Platform files patched.');
}

void _android() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) return;
  var s = f.readAsStringSync();
  if (!s.contains('android.permission.INTERNET')) {
    s = s.replaceFirst('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET"/>');
  }
  if (!s.contains('android.intent.action.DIAL')) {
    const q = '''
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="http"/></intent>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="mailto"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="geo"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="whatsapp"/></intent>''';
    if (s.contains('<queries>')) {
      s = s.replaceFirst('<queries>', '<queries>$q');
    } else {
      s = s.replaceFirst('</manifest>', '    <queries>$q\n    </queries>\n</manifest>');
    }
  }
  s = s.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="$appName"');
  f.writeAsStringSync(s);
}

void _ios() {
  final f = File('ios/Runner/Info.plist');
  if (!f.existsSync()) return;
  var s = f.readAsStringSync();
  if (!s.contains('LSApplicationQueriesSchemes')) {
    s = s.replaceFirst('</dict>\n</plist>', '''	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>https</string>
		<string>http</string>
		<string>tel</string>
		<string>mailto</string>
		<string>sms</string>
		<string>whatsapp</string>
		<string>comgooglemaps</string>
	</array>
</dict>
</plist>''');
  }
  s = s.replaceFirstMapped(RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'), (m) => '${m[1]}$appName${m[2]}');
  f.writeAsStringSync(s);
}
