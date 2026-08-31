import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class AdminComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  const AdminComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<AdminComplaintDetailScreen> createState() => _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState extends State<AdminComplaintDetailScreen> {
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmobiesTheme.card,
        title: Text('Delete Complaint?', style: GoogleFonts.syne(fontWeight: FontWeight.w800)),
        content: Text('This cannot be undone.', style: GoogleFonts.syne(color: EmobiesTheme.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.syne(color: EmobiesTheme.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: GoogleFonts.syne(color: EmobiesTheme.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.updateComplaintStatus(widget.complaintId, 'deleted');
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e', style: GoogleFonts.syne(color: EmobiesTheme.red))),
          );
        }
      }
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return EmobiesTheme.green;
      case 'cancelled': return EmobiesTheme.red;
      case 'pending': return EmobiesTheme.yellow;
      case 'payment_pending': return EmobiesTheme.orange;
      default: return EmobiesTheme.blue;
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
    final color = _statusColor(c.status);

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: Text('#${c.id.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: EmobiesTheme.red),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(c.statusDisplay.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            _section('Customer Info'),
            _infoRow('Name', c.customerName),
            _infoRow('Phone', c.customerPhone),
            if (c.customerEmail != null) _infoRow('Email', c.customerEmail!),
            _infoRow('Address', c.address),
            if (c.landmark != null) _infoRow('Landmark', c.landmark!),
            const SizedBox(height: 16),
            _section('Device Info'),
            _infoRow('Model', c.deviceModel),
            _infoRow('Issue', c.issueDescription),
            if (c.imeiNumber != null) _infoRow('IMEI', c.imeiNumber!),
            const SizedBox(height: 16),
            _section('Assignment'),
            _infoRow('Supervisor', c.assignedSupervisorId ?? 'Not assigned'),
            _infoRow('Delivery Boy', c.assignedDeliveryBoyId ?? 'Not assigned'),
            _infoRow('Service Center', c.assignedServiceCenterId ?? 'Not assigned'),
            const SizedBox(height: 16),
            _section('Payment'),
            _infoRow('Estimated', '₹${c.estimatedCost?.toStringAsFixed(0) ?? '--'}'),
            _infoRow('Final', '₹${c.finalCost?.toStringAsFixed(0) ?? '--'}'),
            _infoRow('Paid', c.isPaid ? 'Yes' : 'No'),
            if (c.paymentMethod != null) _infoRow('Method', c.paymentMethod!),
            if (c.transactionId != null) _infoRow('Transaction', c.transactionId!),
            const SizedBox(height: 16),
            if (c.supervisorNotes != null) ...[
              _section('Notes'),
              _infoRow('Supervisor', c.supervisorNotes!),
            ],
            if (c.serviceCenterNotes != null)
              _infoRow('Service Center', c.serviceCenterNotes!),
            if (c.ignoreReason != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EmobiesTheme.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Ignore Reason: ${c.ignoreReason}', style: GoogleFonts.syne(color: EmobiesTheme.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 13, color: EmobiesTheme.orange)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: GoogleFonts.syne(fontSize: 12, color: EmobiesTheme.muted)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w600, color: EmobiesTheme.text)),
          ),
        ],
      ),
    );
  }
}