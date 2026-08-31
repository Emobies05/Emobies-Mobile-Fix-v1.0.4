import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
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

  Future<void> _updateStatus(String status) async {
    try {
      await _api.updateComplaintStatus(widget.complaintId, status);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.syne(color: EmobiesTheme.red))),
        );
      }
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

    if (_complaint == null) {
      return Scaffold(
        backgroundColor: EmobiesTheme.bg,
        appBar: AppBar(title: const Text('Detail')),
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
              _infoCard('Address', c.address),
              if (c.landmark != null) _infoCard('Landmark', c.landmark!),
              const SizedBox(height: 20),
              // Action buttons based on status
              if (c.status == 'assigned')
                _actionButton('Accept', EmobiesTheme.green, () => _updateStatus('pickup_ongoing')),
              if (c.status == 'pickup_ongoing')
                _actionButton('Reached Customer', EmobiesTheme.blue, () => _updateStatus('reached_customer')),
              if (c.status == 'reached_customer')
                _actionButton('Phone Collected', EmobiesTheme.orange, () {
                  Navigator.of(context).pushNamed(AppRoutes.deliveryUpload, arguments: c.id);
                }),
              if (c.status == 'phone_collected')
                _actionButton('Dropped at Service Center', EmobiesTheme.purple, () => _updateStatus('dropped_sc')),
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