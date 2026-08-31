import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/supabase_service.dart';

String? _fatalError;
String? _fatalStack;

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      _fatalError = details.exceptionAsString();
      _fatalStack = details.stack.toString();
      log('FlutterError: $_fatalError', error: details.exception, stackTrace: details.stack);
    };

    // Lock orientation (fire-and-forget: don't block main() on this)
    SystemChrome.setPreferredOrientations([
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

    // Render immediately — do NOT await anything here.
    // Supabase init happens later, inside the widget, after first frame.
    runApp(const EmobiesApp());
  }, (error, stackTrace) {
    _fatalError = error.toString();
    _fatalStack = stackTrace.toString();
    log('Uncaught zone error: $error', error: error, stackTrace: stackTrace);
    runApp(EmobiesApp(startupError: '$error\n\n$stackTrace'));
  });
}

class EmobiesApp extends StatefulWidget {
  final String? startupError;
  const EmobiesApp({super.key, this.startupError});

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
    if (widget.startupError == null) {
      _init();
    } else {
      _ready = true;
    }
  }

  Future<void> _init() async {
    try {
      // Initialize Supabase here, after the first frame is already on screen.
      try {
        await SupabaseService.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Supabase init timed out after 10s'),
        );
      } catch (e, stackTrace) {
        log('Supabase init error: $e', error: e, stackTrace: stackTrace);
        _fatalError = 'Supabase init error: $e';
        _fatalStack = stackTrace.toString();
        if (mounted) setState(() => _ready = true);
        return;
      }

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
      _fatalError = 'App init error: $e';
      _fatalStack = stackTrace.toString();
      log('App init error: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _ready = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorToShow = widget.startupError ?? _fatalError;

    if (errorToShow != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0C0F14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C0F14),
            title: const Text('Startup Error', style: TextStyle(color: Colors.white)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              '$errorToShow\n\n${_fatalStack ?? ""}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
      );
    }

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
