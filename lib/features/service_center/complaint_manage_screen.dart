import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class ComplaintManageScreen extends StatefulWidget {
  final String complaintId;
  const ComplaintManageScreen({super.key, required this.complaintId});

  @override
  State<ComplaintManageScreen> createState() => _ComplaintManageScreenState();
}

class _ComplaintManageScreenState extends State<ComplaintManageScreen> {
  final _api = ApiService(AuthService());
  ComplaintModel? _complaint;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _api.getComplaint(widget.complaintId);
      setState(() { _complaint = c; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _startRepair() async {
    await _api.updateComplaintStatus(widget.complaintId, 'repair_ongoing');
    _load();
  }

  Future<void> _completeRepair() async {
    await _api.updateComplaintStatus(widget.complaintId, 'repair_completed');
    _load();
  }

  Future<void> _handover() async {
    await _api.updateComplaintStatus(widget.complaintId, 'ready_for_delivery');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07080B),
        body: Center(child: CircularProgressIndicator(color: EmobiesTheme.orange)),
      );
    }

    if (_complaint == null) {
      return Scaffold(
        backgroundColor: EmobiesTheme.bg,
        appBar: AppBar(title: const Text('Complaint')),
        body: Center(child: Text('Not found', style: GoogleFonts.syne(color: EmobiesTheme.muted))),
      );
    }

    final c = _complaint!;

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: Text('#${c.id.substring(0, 8)}')),
      body: RefreshIndicator(
        color: EmobiesTheme.orange,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCard('Device', c.deviceModel),
              _infoCard('Issue', c.issueDescription),
              _infoCard('Customer', c.customerName),
              _infoCard('Phone', c.customerPhone),
              if (c.estimatedCost != null)
                _infoCard('Estimated Cost', '₹${c.estimatedCost!.toStringAsFixed(0)}'),
              const SizedBox(height: 20),
              if (c.status == 'dropped_sc')
                _actionButton('Start Repair', EmobiesTheme.orange, _startRepair),
              if (c.status == 'repair_ongoing')
                _actionButton('Complete Repair', EmobiesTheme.green, _completeRepair),
              if (c.status == 'paid' || c.status == 'repair_completed')
                _actionButton('Handover to Delivery', EmobiesTheme.blue, _handover),
              if (c.status == 'repair_completed' && !c.isPaid)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EmobiesTheme.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    '⚠️ Customer must pay before repair starts.',
                    style: GoogleFonts.syne(color: EmobiesTheme.yellow),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EmobiesTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.syne(fontSize: 10, color: EmobiesTheme.orange, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, color: EmobiesTheme.text)),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(label, style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
    );
  }
}