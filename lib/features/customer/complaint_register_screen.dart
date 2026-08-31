import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';

class ComplaintRegisterScreen extends StatefulWidget {
  const ComplaintRegisterScreen({super.key});

  @override
  State<ComplaintRegisterScreen> createState() => _ComplaintRegisterScreenState();
}

class _ComplaintRegisterScreenState extends State<ComplaintRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _deviceCtrl = TextEditingController();
  final _issueCtrl = TextEditingController();
  final _imeiCtrl = TextEditingController();
  final _api = ApiService(AuthService());
  final _location = LocationService();

  bool _loading = false;
  String? _error;
  File? _image;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final loc = await _location.getCurrentPosition();
    if (loc != null) {
      setState(() {
        _lat = loc.latitude;
        _lng = loc.longitude;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final landmark = _landmarkCtrl.text.trim();
    final device = _deviceCtrl.text.trim();
    final issue = _issueCtrl.text.trim();
    final imei = _imeiCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty || device.isEmpty || issue.isEmpty) {
      setState(() => _error = 'Fill all required fields');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _api.uploadImage(_image!, folder: 'complaints');
      }

      final complaint = await _api.createComplaint({
        'customer_name': name,
        'customer_phone': phone,
        'customer_email': email.isNotEmpty ? email : null,
        'address': address,
        'landmark': landmark.isNotEmpty ? landmark : null,
        'lat': _lat,
        'lng': _lng,
        'device_model': device,
        'issue_description': issue,
        'imei_number': imei.isNotEmpty ? imei : null,
        'images_before': imageUrl != null ? [imageUrl] : null,
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint #${complaint.id.substring(0, 8)} registered!',
              style: GoogleFonts.syne(color: EmobiesTheme.green)),
          backgroundColor: EmobiesTheme.card,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('New Repair Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Customer Info'),
            _field(_nameCtrl, 'Full Name *', Icons.person_outline, required: true),
            _field(_phoneCtrl, 'Phone Number *', Icons.phone_outlined, keyboardType: TextInputType.phone, required: true),
            _field(_emailCtrl, 'Email (optional)', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 8),
            _section('Location'),
            _field(_addressCtrl, 'Address *', Icons.location_on_outlined, maxLines: 2, required: true),
            _field(_landmarkCtrl, 'Landmark (optional)', Icons.place_outlined),
            if (_lat != null)
              Text('📍 Location captured', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.green)),
            const SizedBox(height: 8),
            _section('Device Details'),
            _field(_deviceCtrl, 'Device Model * (e.g., iPhone 15 Pro)', Icons.smartphone_outlined, required: true),
            _field(_issueCtrl, 'Issue Description *', Icons.report_problem_outlined, maxLines: 3, required: true),
            _field(_imeiCtrl, 'IMEI Number (optional)', Icons.numbers_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            _section('Photo'),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: EmobiesTheme.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: EmobiesTheme.border),
                  image: _image != null
                      ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                      : null,
                ),
                child: _image == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: EmobiesTheme.muted, size: 32),
                            const SizedBox(height: 4),
                            Text('Tap to add photo', style: GoogleFonts.syne(fontSize: 11, color: EmobiesTheme.muted)),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
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
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Submit Repair Request', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.orange)),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: EmobiesTheme.text, fontSize: 14),
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: EmobiesTheme.muted, size: 20),
          hintText: hint,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _deviceCtrl.dispose();
    _issueCtrl.dispose();
    _imeiCtrl.dispose();
    super.dispose();
  }
}