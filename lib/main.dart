import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';
import 'kiosk_screen.dart';
import 'setup_screen.dart';

const brand = Color(0xFF14335C);
const gold = Color(0xFFB8935A);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  final cfg = await AppConfig.load();
  runApp(GuestApp(initial: cfg));
}

class GuestApp extends StatefulWidget {
  final AppConfig? initial;
  const GuestApp({super.key, this.initial});
  @override
  State<GuestApp> createState() => _GuestAppState();
}

class _GuestAppState extends State<GuestApp> {
  AppConfig? cfg;
  @override
  void initState() {
    super.initState();
    cfg = widget.initial;
  }

  void _setConfig(AppConfig? c) => setState(() => cfg = c);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: brand, primary: brand, secondary: gold), scaffoldBackgroundColor: Colors.white),
      home: cfg == null
          ? SetupScreen(onDone: (c) async {
              await c.save();
              _setConfig(c);
            })
          : KioskScreen(
              key: ValueKey(cfg!.url),
              config: cfg!,
              onChangeHotel: () async {
                await AppConfig.clear();
                _setConfig(null);
              },
            ),
    );
  }
}
