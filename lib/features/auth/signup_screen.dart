import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _error;
  bool _agreed = false;

  Future<void> _signUp() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Name, phone & password required');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (!_agreed) {
      setState(() => _error = 'Please accept the terms');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final res = await _auth.signUp(
        name: name,
        phone: phone,
        password: pass,
        email: email.isNotEmpty ? email : null,
      );

      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created! Please login.',
                style: GoogleFonts.syne(color: EmobiesTheme.green)),
            backgroundColor: EmobiesTheme.card,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else {
        setState(() => _error = res['error'] ?? 'Sign up failed');
      }
    } catch (e) {
      setState(() => _error = 'Server error. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EmobiesTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: EmobiesTheme.text)),
              const SizedBox(height: 4),
              Text('Join Emobies mobile repair platform', style: GoogleFonts.syne(fontSize: 13, color: EmobiesTheme.text2)),
              const SizedBox(height: 24),
              _field(_nameCtrl, 'Full Name', Icons.person_outline),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_emailCtrl, 'Email (optional)', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_passCtrl, 'Password', Icons.lock_outline, obscure: true),
              const SizedBox(height: 12),
              _field(_confirmCtrl, 'Confirm Password', Icons.lock_outline, obscure: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: EmobiesTheme.orange,
                    side: const BorderSide(color: EmobiesTheme.muted),
                  ),
                  Expanded(
                    child: Text(
                      'I agree to terms & privacy policy',
                      style: GoogleFonts.syne(fontSize: 12, color: EmobiesTheme.text2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EmobiesTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.red)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EmobiesTheme.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text('Create Account', style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false, TextInputType? keyboardType}) {
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
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}