import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/auth_service.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _auth = AuthService();
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final avail = await _auth.canCheckBiometrics();
    final en = await _auth.isBiometricEnabled();
    setState(() {
      _available = avail;
      _enabled = en;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      final authed = await _auth.authenticateWithBiometrics(
        reason: 'Enable biometric login for Emobies',
      );
      if (!authed) return;
    }
    await _auth.setBiometricEnabled(value);
    setState(() => _enabled = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Biometric login enabled' : 'Biometric login disabled',
            style: GoogleFonts.syne(),
          ),
          backgroundColor: value ? EmobiesTheme.green : EmobiesTheme.muted,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Security')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EmobiesTheme.orange))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: EmobiesTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EmobiesTheme.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _available ? Icons.fingerprint : Icons.fingerprint_outlined,
                          size: 64,
                          color: _available ? EmobiesTheme.orange : EmobiesTheme.muted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _available ? 'Biometric Available' : 'Not Available',
                          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: EmobiesTheme.text),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _available
                              ? 'Use fingerprint or face recognition for quick, secure access.'
                              : 'Your device does not support biometric authentication.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.syne(fontSize: 13, color: EmobiesTheme.text2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_available)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: EmobiesTheme.card,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: EmobiesTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Enable Biometric', style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: EmobiesTheme.text)),
                              Text('Quick login with fingerprint', style: GoogleFonts.syne(fontSize: 11, color: EmobiesTheme.text2)),
                            ],
                          ),
                          Switch(
                            value: _enabled,
                            onChanged: _toggle,
                            activeColor: EmobiesTheme.orange,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}