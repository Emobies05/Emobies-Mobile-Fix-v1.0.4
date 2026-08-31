import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class StaffAddScreen extends StatefulWidget {
  const StaffAddScreen({super.key});

  @override
  State<StaffAddScreen> createState() => _StaffAddScreenState();
}

class _StaffAddScreenState extends State<StaffAddScreen> {
  final _api = ApiService(AuthService());
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _role = 'delivery_boy';
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    setState(() { _saving = true; _error = null; });

    try {
      await _api.addStaff({
        'name': name,
        'phone': phone,
        'email': email,
        'role': _role,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff added! Confirmation email sent.', style: GoogleFonts.syne(color: EmobiesTheme.green)),
          backgroundColor: EmobiesTheme.card,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Add Staff')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Staff Details', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.orange)),
              const SizedBox(height: 16),
              _field(_nameCtrl, 'Full Name *', Icons.person_outline, required: true),
              _field(_phoneCtrl, 'Phone Number *', Icons.phone_outlined, keyboardType: TextInputType.phone, required: true),
              _field(_emailCtrl, 'Email *', Icons.email_outlined, keyboardType: TextInputType.emailAddress, required: true),
              const SizedBox(height: 16),
              Text('Role', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.text)),
              const SizedBox(height: 10),
              _roleSelector('Delivery Boy', 'delivery_boy', Icons.local_shipping_outlined, EmobiesTheme.orange),
              _roleSelector('Service Center', 'service_center', Icons.store_outlined, EmobiesTheme.blue),
              _roleSelector('Supervisor', 'supervisor', Icons.supervisor_account_outlined, EmobiesTheme.purple),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: EmobiesTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.red)),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text('Add Staff & Send Email', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              Text('An email will be sent to the staff member with login instructions.',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: EmobiesTheme.text, fontSize: 14),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: EmobiesTheme.muted, size: 20),
          hintText: hint,
        ),
      ),
    );
  }

  Widget _roleSelector(String label, String value, IconData icon, Color color) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : EmobiesTheme.card,
          border: Border.all(color: selected ? color : EmobiesTheme.border),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : EmobiesTheme.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: EmobiesTheme.text)),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
}