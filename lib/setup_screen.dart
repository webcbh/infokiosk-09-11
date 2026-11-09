import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'link_parser.dart';
import 'main.dart' show brand, gold;

class Hotel {
  final String id, name, url;
  Hotel(this.id, this.name, this.url);
}

/// First run (and "Change hotel"): paste the hotel link or the website address, pick the hotel.
class SetupScreen extends StatefulWidget {
  final Future<void> Function(AppConfig) onDone;
  const SetupScreen({super.key, required this.onDone});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _ctl = TextEditingController();
  bool _busy = false;
  String? _error;
  String _site = '';
  String _appName = '';
  List<Hotel> _hotels = [];

  Future<void> _connect() async {
    final parsed = parseLink(_ctl.text);
    if (parsed == null) {
      setState(() => _error = 'Please enter the website address or the hotel link, for example https://www.my-hotel.com');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _hotels = [];
    });
    try {
      http.Response? res;
      String usedBase = '';
      for (final base in restCandidates(parsed, _ctl.text)) {
        try {
          final r = await http.get(Uri.parse('$base/app/mobile')).timeout(const Duration(seconds: 12));
          if (r.statusCode == 200 && r.body.contains('"infokiosk"')) {
            res = r;
            usedBase = base;
            break;
          }
          res ??= r;
        } on FormatException {
          rethrow;
        } catch (_) {
          // try the next candidate
        }
      }
      if (res == null) throw Exception('No answer from the website. Check the address and your internet connection.');
      if (res.statusCode != 200) throw Exception('The site answered with code ${res.statusCode}. Is the Info Kiosk plugin active?');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['app'] != 'infokiosk') throw Exception('This website does not run the Info Kiosk plugin.');
      final list = (data['hotels'] as List).map((h) => Hotel('${h['id']}', '${h['name']}', '${h['url']}')).toList();
      if (list.isEmpty) throw Exception('No hotels are set up on this site yet.');
      _site = usedBase.replaceFirst('/wp-json/infokiosk/v1', '');
      _appName = '${data['name'] ?? ''}';
      // a link that already names a hotel opens straight away
      if (parsed.hotelId != null) {
        final hit = list.where((h) => h.id == parsed.hotelId);
        if (hit.isNotEmpty) {
          await _choose(hit.first);
          return;
        }
      }
      if (list.length == 1) {
        await _choose(list.first);
        return;
      }
      setState(() => _hotels = list);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(Hotel h) async {
    await widget.onDone(AppConfig(site: _site, url: h.url, hotelName: h.name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brand,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Icon(Icons.hotel_rounded, size: 48, color: gold),
                    const SizedBox(height: 12),
                    Text(_hotels.isEmpty ? 'Welcome' : (_appName.isEmpty ? 'Choose your hotel' : _appName), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: brand)),
                    const SizedBox(height: 8),
                    if (_hotels.isEmpty) ...[
                      const Text('Enter the hotel website or the link you received.', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ctl,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _busy ? null : _connect(),
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Website or hotel link', hintText: 'https://www.my-hotel.com'),
                      ),
                      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _connect,
                        style: FilledButton.styleFrom(backgroundColor: brand, padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Continue'),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      for (final h in _hotels)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: OutlinedButton(
                            onPressed: () => _choose(h),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: brand, side: const BorderSide(color: brand)),
                            child: Text(h.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      TextButton(onPressed: () => setState(() => _hotels = []), child: const Text('Back')),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
