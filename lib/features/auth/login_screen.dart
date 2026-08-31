import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/emokey_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _emoKeyCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();
  final _adminSecretCtrl = TextEditingController();

  final _auth = AuthService();
  final _emoKey = EmoKeyService();

  int _loginMode = 0; // 0=customer, 1=staff, 2=admin
  int _fails = 0;
  DateTime? _lockUntil;
  bool _loading = false;
  String? _error;
  bool _biometricAvailable = false;

  bool get _locked => _lockUntil != null && DateTime.now().isBefore(_lockUntil!);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final avail = await _auth.isBiometricAvailable();
    final enabled = await _auth.isBiometricEnabled();
    setState(() => _biometricAvailable = avail && enabled);
  }

  Future<void> _customerLogin() async {
    if (_locked) return;
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Phone and password required');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final res = await _auth.login(phone, pass);
      if (res['success'] == true) {
        final role = res['role'] as String?;
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.getInitialRoute(role),
        );
      } else {
        _fails++;
        if (_fails >= AppConstants.maxLoginAttempts) {
          _lockUntil = DateTime.now().add(AppConstants.lockoutDuration);
          _fails = 0;
          setState(() => _error = 'Too many attempts. Wait 30 seconds.');
        } else {
          setState(() => _error = '${res['error']} (${AppConstants.maxLoginAttempts - _fails} left)');
        }
      }
    } catch (e) {
      setState(() => _error = 'Cannot reach server');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _staffLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final emoKey = _emoKeyCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || emoKey.isEmpty) {
      setState(() => _error = 'Email, password & EmoKey required');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final valid = await _emoKey.verifyKey(emoKey);
      if (!valid) {
        setState(() { _error = 'Invalid EmoKey'; _loading = false; });
        return;
      }

      final res = await _auth.staffLogin(email: email, password: pass, emoKey: emoKey);
      if (res['success'] == true) {
        final role = res['role'] as String?;
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.getInitialRoute(role),
        );
      } else {
        setState(() => _error = res['error'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Server error');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _adminLogin() async {
    final pass = _adminPassCtrl.text.trim();
    final secret = _adminSecretCtrl.text.trim();

    if (pass.isEmpty || secret.isEmpty) {
      setState(() => _error = 'Password & secret key required');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final res = await _auth.superAdminLogin(password: pass, secretKey: secret);
      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
      } else {
        setState(() => _error = res['error'] ?? 'Access denied');
      }
    } catch (e) {
      setState(() => _error = 'Server error');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _biometricLogin() async {
    final authed = await _auth.authenticateWithBiometrics();
    if (authed) {
      final role = await _auth.getRole();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.getInitialRoute(role),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 24),
                _buildModeTabs(),
                const SizedBox(height: 24),
                if (_loginMode == 0) _buildCustomerForm(),
                if (_loginMode == 1) _buildStaffForm(),
                if (_loginMode == 2) _buildAdminForm(),
                const SizedBox(height: 20),
                if (_error != null) _buildError(),
                const SizedBox(height: 20),
                if (_loginMode == 0) _buildBiometricButton(),
                const SizedBox(height: 16),
                if (_loginMode == 0) _buildSignupLink(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        const Text('⬡', style: TextStyle(fontSize: 52, color: EmobiesTheme.orange)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.syne(fontSize: 38, fontWeight: FontWeight.w800, color: EmobiesTheme.text),
            children: const [
              TextSpan(text: 'E', style: TextStyle(color: EmobiesTheme.orange)),
              TextSpan(text: 'mobies'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _pill('📱 Mobile Repair', EmobiesTheme.green),
            _pill('🤖 Emowall AI', EmobiesTheme.purple),
            _pill('🔐 TheWall', EmobiesTheme.orange),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'KANNUR · DUBAI · DIVIN K.K.',
          style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.muted, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildModeTabs() {
    return Container(
      decoration: BoxDecoration(
        color: EmobiesTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmobiesTheme.border),
      ),
      child: Row(
        children: [
          Expanded(child: _modeTab('Customer', 0)),
          Expanded(child: _modeTab('Staff', 1)),
          Expanded(child: _modeTab('Admin', 2)),
        ],
      ),
    );
  }

  Widget _modeTab(String label, int mode) {
    final active = _loginMode == mode;
    return GestureDetector(
      onTap: () => setState(() { _loginMode = mode; _error = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? EmobiesTheme.orange.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? EmobiesTheme.orange : EmobiesTheme.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerForm() {
    return Column(
      children: [
        _textField(_phoneCtrl, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _textField(_passCtrl, 'Password', Icons.lock_outline, obscure: true),
        const SizedBox(height: 16),
        _loginButton('⬡  Unlock Emobies', _customerLogin),
      ],
    );
  }

  Widget _buildStaffForm() {
    return Column(
      children: [
        _textField(_emailCtrl, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _textField(_passCtrl, 'Password', Icons.lock_outline, obscure: true),
        const SizedBox(height: 12),
        _textField(_emoKeyCtrl, 'EmoKey', Icons.vpn_key_outlined),
        const SizedBox(height: 16),
        _loginButton('Staff Login', _staffLogin),
      ],
    );
  }

  Widget _buildAdminForm() {
    return Column(
      children: [
        _textField(_adminPassCtrl, 'Admin Password', Icons.admin_panel_settings_outlined, obscure: true),
        const SizedBox(height: 12),
        _textField(_adminSecretCtrl, 'Secret Key', Icons.security_outlined, obscure: true),
        const SizedBox(height: 16),
        _loginButton('Admin Access', _adminLogin, color: EmobiesTheme.purple),
      ],
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: EmobiesTheme.text, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: EmobiesTheme.muted, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: EmobiesTheme.muted, fontSize: 13),
      ),
      onSubmitted: (_) {
        if (_loginMode == 0) _customerLogin();
        else if (_loginMode == 1) _staffLogin();
        else _adminLogin();
      },
    );
  }

  Widget _loginButton(String label, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading || _locked ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? EmobiesTheme.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          disabledBackgroundColor: EmobiesTheme.muted.withOpacity(0.3),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Widget _buildBiometricButton() {
    if (!_biometricAvailable) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _biometricLogin,
        icon: const Icon(Icons.fingerprint, color: EmobiesTheme.green),
        label: Text('Login with Biometric', style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: EmobiesTheme.green)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: EmobiesTheme.green),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signup),
        child: Text(
          'New here? Create Account',
          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.muted),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EmobiesTheme.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EmobiesTheme.red.withOpacity(0.3)),
      ),
      child: Text(
        _error!,
        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color.withOpacity(0.3)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
  );

  @override
  void dispose() {
    _animController.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _emailCtrl.dispose();
    _emoKeyCtrl.dispose();
    _adminPassCtrl.dispose();
    _adminSecretCtrl.dispose();
    super.dispose();
  }
}