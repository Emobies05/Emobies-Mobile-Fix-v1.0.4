import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0C0F14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e, stackTrace) {
    log('Supabase init error: $e', error: e, stackTrace: stackTrace);
  }

  runApp(const EmobiesApp());
}

class EmobiesApp extends StatefulWidget {
  const EmobiesApp({super.key});

  @override
  State<EmobiesApp> createState() => _EmobiesAppState();
}

class _EmobiesAppState extends State<EmobiesApp> {
  final _auth = AuthService();
  bool _ready = false;
  bool _authed = false;
  String? _role;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final isAuthed = await _auth.init();
      String? role;
      if (isAuthed) {
        role = await _auth.getRole();
      }

      if (!mounted) return;

      setState(() {
        _authed = isAuthed;
        _role = role;
        _ready = true;
      });
    } catch (e, stackTrace) {
      log('App init error: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _ready = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: EmobiesTheme.theme,
        home: Scaffold(
          backgroundColor: EmobiesTheme.bg,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '\u2B21',
                  style: TextStyle(fontSize: 64, color: EmobiesTheme.orange),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: EmobiesTheme.orange,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Emobies',
      debugShowCheckedModeBanner: false,
      theme: EmobiesTheme.theme,
      initialRoute: _authed ? AppRoutes.getInitialRoute(_role) : AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
