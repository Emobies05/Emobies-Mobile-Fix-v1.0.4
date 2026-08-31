import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class PaymentScreen extends StatefulWidget {
  final String complaintId;
  const PaymentScreen({super.key, required this.complaintId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _api = ApiService(AuthService());
  final _costCtrl = TextEditingController();
  ComplaintModel? _complaint;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _api.getComplaint(widget.complaintId);
      setState(() {
        _complaint = c;
        if (c.finalCost != null) _costCtrl.text = c.finalCost!.toStringAsFixed(0);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitCost() async {
    final cost = double.tryParse(_costCtrl.text);
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter valid cost', style: GoogleFonts.syne())),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.updateComplaintStatus(widget.complaintId, 'repair_completed', extra: {
        'final_cost': cost,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cost set: ₹${cost.toStringAsFixed(0)}', style: GoogleFonts.syne(color: EmobiesTheme.green)),
          backgroundColor: EmobiesTheme.card,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07080B),
        body: Center(child: CircularProgressIndicator(color: EmobiesTheme.orange)),
      );
    }

    final c = _complaint!;

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Payment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: EmobiesTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EmobiesTheme.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text('Repair Cost', style: GoogleFonts.syne(fontSize: 14, color: EmobiesTheme.text2)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹', style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: EmobiesTheme.orange)),
                      Text(
                        c.finalCost != null ? c.finalCost!.toStringAsFixed(0) : '--',
                        style: GoogleFonts.syne(fontSize: 48, fontWeight: FontWeight.w800, color: EmobiesTheme.text),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Device: ${c.deviceModel}', style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14, color: EmobiesTheme.text)),
            Text(c.issueDescription, style: const TextStyle(fontSize: 12, color: EmobiesTheme.text2)),
            const SizedBox(height: 20),
            if (c.finalCost == null) ...[
              Text('Set Final Cost', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.orange)),
              const SizedBox(height: 10),
              TextField(
                controller: _costCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: EmobiesTheme.text, fontSize: 18),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.currency_rupee, color: EmobiesTheme.muted),
                  hintText: 'Enter final cost',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submitCost,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text('Set Cost', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EmobiesTheme.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: EmobiesTheme.green),
                    const SizedBox(width: 12),
                    Text(
                      c.isPaid ? 'Payment received!' : 'Cost set. Waiting for payment.',
                      style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: EmobiesTheme.green),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Payment methods info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EmobiesTheme.card,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: EmobiesTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Methods', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.text)),
                  const SizedBox(height: 10),
                  _payMethod('Cash', Icons.money),
                  _payMethod('UPI / GPay / PhonePe', Icons.account_balance_wallet_outlined),
                  _payMethod('Card', Icons.credit_card_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payMethod(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: EmobiesTheme.orange),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.syne(fontSize: 13, color: EmobiesTheme.text2)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    super.dispose();
  }
}