import 'package:shared_preferences/shared_preferences.dart';

/// What the app remembers: which site and which hotel to open.
class AppConfig {
  final String site; // https://www.my-hotel.com
  final String url; // full address the WebView opens (kiosk page + ?mobile=true&hotelId=..)
  final String hotelName;
  const AppConfig({required this.site, required this.url, this.hotelName = ''});

  static Future<AppConfig?> load() async {
    final p = await SharedPreferences.getInstance();
    final site = p.getString('site');
    final url = p.getString('url');
    if (site == null || url == null || url.isEmpty) return null;
    return AppConfig(site: site, url: url, hotelName: p.getString('hotelName') ?? '');
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('site', site);
    await p.setString('url', url);
    await p.setString('hotelName', hotelName);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('site');
    await p.remove('url');
    await p.remove('hotelName');
  }
}
