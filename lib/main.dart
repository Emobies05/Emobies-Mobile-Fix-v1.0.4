import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

const String _apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://your-app.ondigitalocean.app',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const EmobiesApp());
}

class EmobiesTheme {
  static const bg      = Color(0xFF07080B);
  static const surface = Color(0xFF0C0F14);
  static const card    = Color(0xFF111519);
  static const orange  = Color(0xFFFF5500);
  static const green   = Color(0xFF00E676);
  static const yellow  = Color(0xFFFBBF24);
  static const red     = Color(0xFFEF4444);
  static const blue    = Color(0xFF3B82F6);
  static const purple  = Color(0xFFA855F7);
  static const text    = Color(0xFFEEF0F4);
  static const text2   = Color(0xFF8892A4);
  static const muted   = Color(0xFF424A58);
  static const border  = Color(0xFF1A1F28);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: orange, secondary: purple, surface: card, error: red,
    ),
    textTheme: GoogleFonts.syneTextTheme().apply(bodyColor: text, displayColor: text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF1C2230))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: orange, width: 1.5)),
      hintStyle: const TextStyle(color: muted, fontSize: 13),
    ),
  );
}

class AuthState extends ChangeNotifier {
  static const _storage  = FlutterSecureStorage();
  static const _tokenKey = 'ew_token';
  static const _roleKey  = 'ew_role';
  String? _token;
  String  _role  = 'customer';
  bool    _ready = false;
  String? get token  => _token;
  String  get role   => _role;
  bool    get ready  => _ready;
  bool    get authed => _token != null;
  Map<String, String> get authHeaders => {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'};

  Future<void> init() async {
    final stored = await _storage.read(key: _tokenKey);
    if (stored != null) {
      try {
        final res = await http.get(Uri.parse('$_apiBase/api/user/profile'), headers: {'Authorization': 'Bearer $stored'}).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) { _token = stored; _role = await _storage.read(key: _roleKey) ?? 'customer'; }
        else { await _storage.deleteAll(); }
      } catch (_) { _token = stored; _role = await _storage.read(key: _roleKey) ?? 'customer'; }
    }
    _ready = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String password) async {
    final res = await http.post(Uri.parse('$_apiBase/api/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'password': password})).timeout(const Duration(seconds: 10));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['token'] != null) {
      _token = data['token'] as String;
      _role  = data['role']  as String? ?? 'customer';
      await _storage.write(key: _tokenKey, value: _token);
      await _storage.write(key: _roleKey,  value: _role);
      notifyListeners();
      return {'success': true};
    }
    return {'success': false, 'error': data['error'] ?? 'Wrong password'};
  }

  Future<void> logout() async { _token = null; _role = 'customer'; await _storage.deleteAll(); notifyListeners(); }
}

class EmobiesApp extends StatefulWidget {
  const EmobiesApp({super.key});
  @override
  State<EmobiesApp> createState() => _EmobiesAppState();
}

class _EmobiesAppState extends State<EmobiesApp> {
  final _auth = AuthState();
  @override
  void initState() { super.initState(); _auth.init(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _auth,
      builder: (context, _) {
        if (!_auth.ready) return const MaterialApp(home: Scaffold(backgroundColor: EmobiesTheme.bg, body: Center(child: CircularProgressIndicator(color: EmobiesTheme.orange))));
        return MaterialApp(
          title: 'Emobies', debugShowCheckedModeBanner: false, theme: EmobiesTheme.theme,
          home: _auth.authed ? MainShell(auth: _auth) : LoginScreen(auth: _auth),
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  final AuthState auth;
  const LoginScreen({super.key, required this.auth});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pass = TextEditingController();
  final _localAuth = LocalAuthentication();
  String? _error;
  bool _loading = false;
  int _fails = 0;
  DateTime? _lockUntil;
  bool get _locked => _lockUntil != null && DateTime.now().isBefore(_lockUntil!);

  Future<void> _login() async {
    if (_locked) return;
    final pw = _pass.text.trim();
    if (pw.isEmpty) { setState(() => _error = 'Enter your password'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.auth.login(pw);
      if (!result['success']) {
        _fails++;
        if (_fails >= 3) { _lockUntil = DateTime.now().add(const Duration(seconds: 30)); _fails = 0; setState(() => _error = '🔒 Too many attempts. Wait 30 seconds.'); }
        else { setState(() => _error = '❌ Wrong password. ${3 - _fails} attempts left.'); }
        _pass.clear();
      }
    } catch (e) { setState(() => _error = '⚠️ Cannot reach server. Check connection.'); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _biometric() async {
    try {
      final ok = await _localAuth.authenticate(localizedReason: 'Unlock Emobies', options: const AuthenticationOptions(biometricOnly: true));
      if (ok) setState(() {});
    } catch (_) { setState(() => _error = 'Biometric failed. Use password.'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⬡', style: TextStyle(fontSize: 48, color: EmobiesTheme.orange)),
              const SizedBox(height: 12),
              RichText(text: TextSpan(
                style: GoogleFonts.syne(fontSize: 38, fontWeight: FontWeight.w800, color: EmobiesTheme.text),
                children: const [TextSpan(text: 'E', style: TextStyle(color: EmobiesTheme.orange)), TextSpan(text: 'mobies')],
              )),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                _pill('📱 Mobile Repair', EmobiesTheme.green),
                _pill('🔐 TheWall', EmobiesTheme.orange),
                _pill('🤖 Emowall AI', EmobiesTheme.purple),
              ]),
              const SizedBox(height: 6),
              Text('KANNUR · DUBAI · DIVIN K.K.', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.muted, letterSpacing: 2)),
              const SizedBox(height: 32),
              TextField(controller: _pass, obscureText: true, style: const TextStyle(color: EmobiesTheme.text, letterSpacing: 4), textAlign: TextAlign.center, decoration: const InputDecoration(hintText: 'Enter Password'), onSubmitted: (_) => _login()),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading || _locked ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: EmobiesTheme.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('⬡  Unlock Emobies'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, height: 48,
                child: OutlinedButton(
                  onPressed: _biometric,
                  style: OutlinedButton.styleFrom(foregroundColor: EmobiesTheme.text2, side: const BorderSide(color: EmobiesTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: const Text('☝  Fingerprint Login'),
                ),
              ),
              if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.red), textAlign: TextAlign.center)],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
  );

  @override
  void dispose() { _pass.dispose(); super.dispose(); }
}

class MainShell extends StatefulWidget {
  final AuthState auth;
  const MainShell({super.key, required this.auth});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final tabs = [const DashboardTab(), const RepairsTab(), const EmoCoinsTab(), const TheWallTab()];
    return Scaffold(
      body: tabs[_tab],
      bottomNavigationBar: NavigationBar(
        backgroundColor: EmobiesTheme.surface,
        selectedIndex: _tab,
        indicatorColor: EmobiesTheme.orange.withOpacity(0.15),
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: EmobiesTheme.orange), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build, color: EmobiesTheme.orange), label: 'Repairs'),
          NavigationDestination(icon: Icon(Icons.toll_outlined), selectedIcon: Icon(Icons.toll, color: EmobiesTheme.orange), label: 'EmoCoins'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: EmobiesTheme.orange), label: 'TheWall'),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RichText(text: TextSpan(style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: EmobiesTheme.text),
                  children: const [TextSpan(text: 'E', style: TextStyle(color: EmobiesTheme.orange)), TextSpan(text: 'mobies')])),
                Text('Kannur → Dubai', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.muted)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: EmobiesTheme.green.withOpacity(0.1), border: Border.all(color: EmobiesTheme.green.withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
                child: Text('● STABLE', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.green, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              _statCard('Active Repairs', '8', EmobiesTheme.orange),
              const SizedBox(width: 10),
              _statCard('EmoCoins', '—', EmobiesTheme.purple),
              const SizedBox(width: 10),
              _statCard('APK Installs', '847', EmobiesTheme.green),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: EmobiesTheme.card, border: Border.all(color: EmobiesTheme.border), borderRadius: BorderRadius.circular(13)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🤖 Emowall AI', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.purple, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('Load dashboard to get AI summary of your portfolio and repairs.', style: TextStyle(fontSize: 13, color: EmobiesTheme.text2)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: EmobiesTheme.card, border: Border.all(color: color.withOpacity(0.2)), borderRadius: BorderRadius.circular(13)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.muted)),
      ]),
    ),
  );
}

class RepairsTab extends StatefulWidget {
  const RepairsTab({super.key});
  @override
  State<RepairsTab> createState() => _RepairsTabState();
}

class _RepairsTabState extends State<RepairsTab> {
  List _repairs = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse('$_apiBase/api/repairs'));
      if (res.statusCode == 200) setState(() { _repairs = jsonDecode(res.body) as List; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(backgroundColor: EmobiesTheme.surface, title: Text('Live Repairs', style: GoogleFonts.syne(fontWeight: FontWeight.w800)), actions: [IconButton(icon: const Icon(Icons.refresh, color: EmobiesTheme.orange), onPressed: _load)]),
      body: _loading ? const Center(child: CircularProgressIndicator(color: EmobiesTheme.orange))
          : _repairs.isEmpty ? Center(child: Text('No active repairs', style: TextStyle(color: EmobiesTheme.muted)))
          : ListView.separated(padding: const EdgeInsets.all(16), itemCount: _repairs.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _repairCard(_repairs[i] as Map<String, dynamic>)),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: EmobiesTheme.orange, icon: const Icon(Icons.add), label: Text('New Repair', style: GoogleFonts.syne(fontWeight: FontWeight.w800)), onPressed: () {}),
    );
  }

  Widget _repairCard(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? 'Pending';
    final color = status == 'Done ✓' ? EmobiesTheme.green : status == 'In Progress' ? EmobiesTheme.yellow : EmobiesTheme.blue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: EmobiesTheme.card, border: Border.all(color: EmobiesTheme.border), borderRadius: BorderRadius.circular(13)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r['device'] ?? 'Device', style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(r['customerLocation'] ?? '', style: TextStyle(fontSize: 12, color: EmobiesTheme.text2)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class EmoCoinsTab extends StatelessWidget {
  const EmoCoinsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(backgroundColor: EmobiesTheme.surface, title: Text('EmoCoins', style: GoogleFonts.syne(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: EmobiesTheme.card, border: Border.all(color: EmobiesTheme.orange.withOpacity(0.3)), borderRadius: BorderRadius.circular(13)),
            child: Column(children: [
              Text('— EmoCoins', style: GoogleFonts.syne(fontSize: 32, fontWeight: FontWeight.w800, color: EmobiesTheme.orange)),
              const SizedBox(height: 4),
              Text('1,000 coins → USDT/SOL/ETH', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
            ]),
          ),
          const SizedBox(height: 16),
          ...[
            ('🎰 Daily Scratch', '5–50 coins · Once per day', EmobiesTheme.purple),
            ('📅 Daily Check-in', '+1 coin · First 10,000 users', EmobiesTheme.blue),
            ('👥 Refer a Friend', '100 coins per referral', EmobiesTheme.green),
            ('💬 WhatsApp', '+50 coins · One time', const Color(0xFF25D366)),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: EmobiesTheme.card, border: Border.all(color: item.$3.withOpacity(0.2)), borderRadius: BorderRadius.circular(13)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.$1, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(item.$2, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
                ])),
                Icon(Icons.chevron_right, color: item.$3),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

class TheWallTab extends StatelessWidget {
  const TheWallTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(backgroundColor: EmobiesTheme.surface, title: Text('TheWall · ₹52 Crore', style: GoogleFonts.syne(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ...[
            ('🔷', 'Arbitrum · ETH', '₹12.8 Crore · 842.1 ETH staked · 4.8% APY'),
            ('◎', 'Solana', '184 SOL · +3.2% today'),
            ('🔴', 'TRON Stake', '12,400 TRX · Claim ready ⚡'),
            ('👻', 'AAVE · DeFi', 'Liquidity active · Yield accumulating'),
          ].map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: EmobiesTheme.card, border: Border.all(color: EmobiesTheme.border), borderRadius: BorderRadius.circular(13)),
              child: Row(children: [
                Text(c.$1, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.$2, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: EmobiesTheme.text)),
                  const SizedBox(height: 2),
                  Text(c.$3, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.text2)),
                ])),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}
