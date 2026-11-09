import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'app_config.dart';
import 'main.dart' show brand;

/// Full-screen guest app: the hotel's Info Kiosk page in a native WebView, plus
///  * Android back button = back inside the app, double back = leave
///  * tel:, mailto:, maps, WhatsApp and other websites open in the matching phone app
///  * friendly offline screen with Retry
///  * press and hold the top-left corner of the page for 1.5 s: Reload / Change hotel (hidden from guests)
class KioskScreen extends StatefulWidget {
  final AppConfig config;
  final VoidCallback onChangeHotel;
  const KioskScreen({super.key, required this.config, required this.onChangeHotel});
  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> with WidgetsBindingObserver {
  late final WebViewController _web;
  bool _loading = true;
  bool _offline = false;
  int _progress = 0;
  DateTime? _lastBack;
  DateTime? _pausedAt;

  String get _origin {
    final u = Uri.parse(widget.config.url);
    return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('HotelApp', onMessageReceived: (m) {
        if (m.message == 'menu' && mounted) _menu();
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() {
          _loading = true;
          _offline = false;
        }),
        onProgress: (p) => setState(() => _progress = p),
        onPageFinished: (_) {
          setState(() => _loading = false);
          _web.runJavaScript(_hotZoneJs);
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) setState(() => _offline = true);
        },
        onNavigationRequest: _onNav,
      ));
    _start();
  }

  // keep the phone's own user agent (the plugin shows the mobile layout for phones) and add our name
  Future<void> _start() async {
    try {
      final ua = await _web.getUserAgent();
      if (ua != null && ua.isNotEmpty) await _web.setUserAgent('$ua HotelGuideApp/1.0');
    } catch (_) {}
    await _web.loadRequest(Uri.parse(widget.config.url));
  }

  // invisible 64x64 corner (top-left) inside the page: press and hold 1.5 s opens the staff menu
  static const _hotZoneJs = """
(function(){
  if (window.__hgZone) return; window.__hgZone = true; window.IK_NATIVE_APP = true;
  var z = document.createElement('div');
  z.style.cssText = 'position:fixed;top:0;left:0;width:64px;height:64px;z-index:2147483647;background:transparent;-webkit-touch-callout:none;-webkit-user-select:none;user-select:none';
  var t = null;
  function start(){ clearTimeout(t); t = setTimeout(function(){ HotelApp.postMessage('menu'); }, 1500); }
  function stop(){ clearTimeout(t); }
  z.addEventListener('touchstart', start, {passive:true});
  z.addEventListener('touchend', stop); z.addEventListener('touchcancel', stop); z.addEventListener('touchmove', stop, {passive:true});
  z.addEventListener('contextmenu', function(e){ e.preventDefault(); });
  document.body.appendChild(z);
})();
""";

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // coming back to the app after a long time: refresh so the guest never sees stale content
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _pausedAt = DateTime.now();
    if (state == AppLifecycleState.resumed && _pausedAt != null) {
      if (DateTime.now().difference(_pausedAt!) > const Duration(minutes: 20)) _web.reload();
      _pausedAt = null;
    }
  }

  Future<NavigationDecision> _onNav(NavigationRequest r) async {
    final uri = Uri.tryParse(r.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final sameSite = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}' == _origin;
      // other websites (booking engines, social, maps links...) open in the phone's browser
      if (sameSite || uri.scheme == 'about') return NavigationDecision.navigate;
      if (!r.isMainFrame) return NavigationDecision.navigate; // embedded maps / videos stay inline
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationDecision.prevent;
    }
    if (uri.scheme == 'about' || uri.scheme == 'blob' || uri.scheme == 'data') return NavigationDecision.navigate;
    // tel:, mailto:, sms:, whatsapp:, geo:, comgooglemaps: ...
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    return NavigationDecision.prevent;
  }

  Future<void> _back() async {
    if (await _web.canGoBack()) {
      await _web.goBack();
      return;
    }
    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Press back again to leave'), duration: Duration(seconds: 2)));
  }

  void _menu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.hotel), title: Text(widget.config.hotelName.isEmpty ? 'Hotel' : widget.config.hotelName), subtitle: Text(widget.config.site)),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reload'),
            onTap: () {
              Navigator.pop(ctx);
              _web.reload();
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Change hotel'),
            onTap: () {
              Navigator.pop(ctx);
              widget.onChangeHotel();
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(children: [
            Positioned.fill(child: WebViewWidget(controller: _web)),
            if (_loading && !_offline) Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(value: _progress > 0 ? _progress / 100 : null, minHeight: 3, color: brand, backgroundColor: Colors.transparent)),
            if (_offline)
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.wifi_off_rounded, size: 64, color: brand),
                    const SizedBox(height: 16),
                    const Text("You're offline", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: brand)),
                    const SizedBox(height: 8),
                    const Text('Please check your internet connection and try again.', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: brand),
                      onPressed: () {
                        setState(() => _offline = false);
                        _web.loadRequest(Uri.parse(widget.config.url));
                      },
                      child: const Text('Try again'),
                    ),
                    TextButton(onPressed: widget.onChangeHotel, child: const Text('Change hotel')),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
