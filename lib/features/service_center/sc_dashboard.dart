import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class SCDashboard extends StatefulWidget {
  const SCDashboard({super.key});

  @override
  State<SCDashboard> createState() => _SCDashboardState();
}

class _SCDashboardState extends State<SCDashboard> {
  final _api = ApiService(AuthService());
  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _api.getComplaints(
        role: 'service_center',
        userId: AuthService().currentUser?.id,
      );
      setState(() { _complaints = list; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final received = _complaints.where((c) => c.status == 'dropped_sc').toList();
    final repairing = _complaints.where((c) => c.status == 'repair_ongoing').toList();
    final pendingPay = _complaints.where((c) => c.status == 'repair_completed').toList();
    final ready = _complaints.where((c) => c.status == 'paid' || c.status == 'ready_for_delivery').toList();

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: const Text('Service Center'),
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
                        _statCard('Received', '${received.length}', EmobiesTheme.blue),
                        const SizedBox(width: 10),
                        _statCard('Repairing', '${repairing.length}', EmobiesTheme.orange),
                        const SizedBox(width: 10),
                        _statCard('Ready', '${ready.length}', EmobiesTheme.green),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (received.isNotEmpty) ...[
                      Text('Received Devices', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                      const SizedBox(height: 12),
                      ...received.map((c) => _complaintCard(c, 'Confirm Received', () async {
                        await _api.updateComplaintStatus(c.id, 'repair_ongoing');
                        _load();
                      })),
                    ],
                    if (repairing.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Under Repair', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                      const SizedBox(height: 12),
                      ...repairing.map((c) => _complaintCard(c, 'Complete Repair', () {
                        Navigator.of(context).pushNamed(AppRoutes.scRepairComplete, arguments: c.id);
                      })),
                    ],
                    if (pendingPay.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Payment Pending', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                      const SizedBox(height: 12),
                      ...pendingPay.map((c) => _paymentCard(c)),
                    ],
                    if (ready.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Ready for Handover', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                      const SizedBox(height: 12),
                      ...ready.map((c) => _complaintCard(c, 'Handover to Delivery', () async {
                        await _api.updateComplaintStatus(c.id, 'handover_delivery');
                        _load();
                      })),
                    ],
                    if (received.isEmpty && repairing.isEmpty && pendingPay.isEmpty && ready.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text('No devices at service center', style: GoogleFonts.syne(color: EmobiesTheme.muted)),
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

  Widget _complaintCard(ComplaintModel c, String actionLabel, VoidCallback onAction) {
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
          Text(c.deviceModel, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14, color: EmobiesTheme.text)),
          Text(c.issueDescription, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: EmobiesTheme.text2)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                  child: Text(actionLabel, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              _iconBtn(Icons.chat_outlined, () {
                Navigator.of(context).pushNamed(AppRoutes.supervisorChat, arguments: {
                  'chatId': c.id,
                  'title': c.deviceModel,
                  'participants': [c.customerId],
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(ComplaintModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        border: Border.all(color: EmobiesTheme.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.deviceModel, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14, color: EmobiesTheme.text)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Final Cost:', style: GoogleFonts.syne(fontWeight: FontWeight.w600)),
              Text('₹${c.finalCost?.toStringAsFixed(0) ?? '--'}',
                  style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18, color: EmobiesTheme.orange)),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.scPayment, arguments: c.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: EmobiesTheme.green,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Text('View Payment Details', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: EmobiesTheme.surface, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: EmobiesTheme.orange),
      ),
    );
  }
}