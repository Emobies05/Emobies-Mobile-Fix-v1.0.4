import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';
import '../../core/models/complaint_model.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final _api = ApiService(AuthService());
  final _location = LocationService();
  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  Timer? _locTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startLocationTracking();
  }

  Future<void> _load() async {
    try {
      final list = await _api.getComplaints(
        role: 'delivery_boy',
        userId: AuthService().currentUser?.id,
      );
      setState(() { _complaints = list; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startLocationTracking() {
    _location.startTracking();
    _locTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final loc = _location.lastLocation;
      if (loc != null) {
        await _api.updateLocation(loc.latitude, loc.longitude);
      }
    });
  }

  Future<void> _acceptComplaint(String id) async {
    try {
      await _api.updateComplaintStatus(id, 'accepted');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.syne(color: EmobiesTheme.red))),
        );
      }
    }
  }

  Future<void> _ignoreComplaint(String id, String reason) async {
    try {
      await _api.updateComplaintStatus(id, 'cancelled', extra: {'ignore_reason': reason});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.syne(color: EmobiesTheme.red))),
        );
      }
    }
  }

  Future<void> _showIgnoreDialog(String id) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmobiesTheme.card,
        title: Text('Ignore Complaint', style: GoogleFonts.syne(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: EmobiesTheme.text),
          decoration: const InputDecoration(hintText: 'Reason for ignoring...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.syne(color: EmobiesTheme.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _ignoreComplaint(id, ctrl.text);
            },
            child: Text('Ignore', style: GoogleFonts.syne(color: EmobiesTheme.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    _locTimer?.cancel();
    await _location.stopTracking();
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final assigned = _complaints.where((c) => c.status == 'assigned').toList();
    final active = _complaints.where((c) =>
      c.status != 'pending' && c.status != 'assigned' && c.status != 'completed' && c.status != 'cancelled'
    ).toList();

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: const Text('Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: EmobiesTheme.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EmobiesTheme.orange))
          : RefreshIndicator(
              color: EmobiesTheme.orange,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _statCard('New', '${assigned.length}', EmobiesTheme.yellow),
                        const SizedBox(width: 10),
                        _statCard('Active', '${active.length}', EmobiesTheme.blue),
                        const SizedBox(width: 10),
                        _statCard('Total', '${_complaints.length}', EmobiesTheme.green),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (assigned.isNotEmpty) ...[
                      Text('New Assignments', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                      const SizedBox(height: 12),
                      ...assigned.map((c) => _newAssignmentCard(c)),
                    ],
                    const SizedBox(height: 20),
                    if (active.isNotEmpty) ...[
                      Text('Active Deliveries', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                      const SizedBox(height: 12),
                      ...active.map((c) => _activeCard(c)),
                    ],
                    if (assigned.isEmpty && active.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text('No complaints assigned', style: GoogleFonts.syne(color: EmobiesTheme.muted)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EmobiesTheme.card,
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.muted)),
          ],
        ),
      ),
    );
  }

  Widget _newAssignmentCard(ComplaintModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        border: Border.all(color: EmobiesTheme.yellow.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.deviceModel, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14, color: EmobiesTheme.text)),
          Text(c.customerPhone, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.muted)),
          Text(c.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: EmobiesTheme.text2)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptComplaint(c.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EmobiesTheme.green,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Text('Accept', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showIgnoreDialog(c.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EmobiesTheme.red,
                    side: const BorderSide(color: EmobiesTheme.red),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Text('Ignore', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeCard(ComplaintModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        border: Border.all(color: EmobiesTheme.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c.deviceModel, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: EmobiesTheme.text)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EmobiesTheme.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(c.statusDisplay, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.blue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _actionBtn(Icons.location_on_outlined, 'Reached Customer', () {
            Navigator.of(context).pushNamed(AppRoutes.deliveryLocation, arguments: {
              'type': 'customer',
              'complaintId': c.id,
            });
          }),
          const SizedBox(height: 6),
          _actionBtn(Icons.camera_alt_outlined, 'Upload Phone Photo', () {
            Navigator.of(context).pushNamed(AppRoutes.deliveryUpload, arguments: c.id);
          }),
          const SizedBox(height: 6),
          _actionBtn(Icons.local_shipping_outlined, 'Dropped at Service Center', () {
            Navigator.of(context).pushNamed(AppRoutes.deliveryLocation, arguments: {
              'type': 'service_center',
              'complaintId': c.id,
            });
          }),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: EmobiesTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EmobiesTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: EmobiesTheme.orange),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w600, color: EmobiesTheme.text)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 16, color: EmobiesTheme.muted),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locTimer?.cancel();
    super.dispose();
  }
}