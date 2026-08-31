import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class ComplaintAssignScreen extends StatefulWidget {
  final String? complaintId;
  const ComplaintAssignScreen({super.key, this.complaintId});

  @override
  State<ComplaintAssignScreen> createState() => _ComplaintAssignScreenState();
}

class _ComplaintAssignScreenState extends State<ComplaintAssignScreen> {
  final _api = ApiService(AuthService());
  ComplaintModel? _complaint;
  List<Map<String, dynamic>> _deliveryBoys = [];
  List<Map<String, dynamic>> _serviceCenters = [];
  String? _selectedDeliveryBoy;
  String? _selectedServiceCenter;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.complaintId != null) {
        final c = await _api.getComplaint(widget.complaintId!);
        final dbs = await _api.getStaff(role: 'delivery_boy');
        final scs = await _api.getStaff(role: 'service_center');
        setState(() {
          _complaint = c;
          _deliveryBoys = dbs;
          _serviceCenters = scs;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _assign() async {
    if (_selectedDeliveryBoy == null || _selectedServiceCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select both delivery boy and service center', style: GoogleFonts.syne())),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.assignComplaint(
        widget.complaintId!,
        deliveryBoyId: _selectedDeliveryBoy,
        serviceCenterId: _selectedServiceCenter,
      );
      await _api.updateComplaintStatus(widget.complaintId!, 'assigned');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assigned successfully!', style: GoogleFonts.syne(color: EmobiesTheme.green)),
          backgroundColor: EmobiesTheme.card,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e', style: GoogleFonts.syne(color: EmobiesTheme.red))),
      );
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

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Assign Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_complaint != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EmobiesTheme.card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: EmobiesTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_complaint!.deviceModel, style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                    Text(_complaint!.customerPhone, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.muted)),
                    Text(_complaint!.address, style: const TextStyle(fontSize: 12, color: EmobiesTheme.text2)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text('Select Delivery Boy', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.orange)),
            const SizedBox(height: 10),
            ..._deliveryBoys.map((db) => _selectableCard(
              db['name'] ?? 'Unknown',
              db['phone'] ?? '',
              db['id'] == _selectedDeliveryBoy,
                  () => setState(() => _selectedDeliveryBoy = db['id']),
            )),
            const SizedBox(height: 20),
            Text('Select Service Center', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.orange)),
            const SizedBox(height: 10),
            ..._serviceCenters.map((sc) => _selectableCard(
              sc['name'] ?? 'Unknown',
              sc['phone'] ?? '',
              sc['id'] == _selectedServiceCenter,
                  () => setState(() => _selectedServiceCenter = sc['id']),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _assign,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Assign Now', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectableCard(String title, String subtitle, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? EmobiesTheme.orange.withOpacity(0.1) : EmobiesTheme.card,
          border: Border.all(color: selected ? EmobiesTheme.orange : EmobiesTheme.border),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: EmobiesTheme.text)),
                  Text(subtitle, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: EmobiesTheme.orange, size: 24),
          ],
        ),
      ),
    );
  }
}