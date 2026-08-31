import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class RepairCompleteScreen extends StatefulWidget {
  final String complaintId;
  const RepairCompleteScreen({super.key, required this.complaintId});

  @override
  State<RepairCompleteScreen> createState() => _RepairCompleteScreenState();
}

class _RepairCompleteScreenState extends State<RepairCompleteScreen> {
  final _api = ApiService(AuthService());
  final _notesCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _submit() async {
    final notes = _notesCtrl.text.trim();
    final cost = double.tryParse(_costCtrl.text);

    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter valid final cost', style: GoogleFonts.syne())),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.updateComplaintStatus(widget.complaintId, 'repair_completed', extra: {
        'final_cost': cost,
        'service_center_notes': notes.isNotEmpty ? notes : null,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Repair marked complete!', style: GoogleFonts.syne(color: EmobiesTheme.green)),
          backgroundColor: EmobiesTheme.card,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e', style: GoogleFonts.syne(color: EmobiesTheme.red))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Complete Repair')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Final Cost *', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.orange)),
            const SizedBox(height: 8),
            TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EmobiesTheme.text, fontSize: 18),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.currency_rupee, color: EmobiesTheme.muted),
                hintText: 'Enter final repair cost',
              ),
            ),
            const SizedBox(height: 20),
            Text('Repair Notes', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: const TextStyle(color: EmobiesTheme.text),
              decoration: const InputDecoration(
                hintText: 'What was repaired? Parts replaced? Warranty info...',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Mark Repair Complete', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }
}