import 'staff_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final _api = ApiService(AuthService());
  List<ComplaintModel> _complaints = [];
  int _tab = 0;
  bool _loading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final complaints = await _api.getComplaints();
      final stats = await _api.getDashboardStats();
      setState(() {
        _complaints = complaints;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return EmobiesTheme.yellow;
      case 'completed': return EmobiesTheme.green;
      case 'cancelled': return EmobiesTheme.red;
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

    final pending = _complaints.where((c) => c.status == 'pending').toList();
    final active = _complaints.where((c) =>
      c.status != 'completed' && c.status != 'cancelled' && c.status != 'pending'
    ).toList();

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: const Text('Supervisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: EmobiesTheme.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: _tab == 0 ? _buildDashboard(pending, active) : _buildStaffTab(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: EmobiesTheme.surface,
        selectedIndex: _tab,
        indicatorColor: EmobiesTheme.orange.withOpacity(0.15),
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: EmobiesTheme.orange), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: EmobiesTheme.orange), label: 'Staff'),
        ],
      ),
    );
  }

  Widget _buildDashboard(List<ComplaintModel> pending, List<ComplaintModel> active) {
    return RefreshIndicator(
      color: EmobiesTheme.orange,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(
              children: [
                _statCard('Pending', '${pending.length}', EmobiesTheme.yellow),
                const SizedBox(width: 10),
                _statCard('Active', '${active.length}', EmobiesTheme.blue),
                const SizedBox(width: 10),
                _statCard('Completed', '${_stats?['completed'] ?? 0}', EmobiesTheme.green),
              ],
            ),
            const SizedBox(height: 20),
            // Pending Complaints
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pending Complaints', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                Text('${pending.length}', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: EmobiesTheme.orange)),
              ],
            ),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: EmobiesTheme.card, borderRadius: BorderRadius.circular(13)),
                child: Center(child: Text('No pending complaints', style: GoogleFonts.syne(color: EmobiesTheme.muted))),
              )
            else
              ...pending.take(5).map((c) => _pendingCard(c)),
            const SizedBox(height: 20),
            // Active Complaints
            Text('Active Repairs', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
            const SizedBox(height: 12),
            if (active.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: EmobiesTheme.card, borderRadius: BorderRadius.circular(13)),
                child: Center(child: Text('No active repairs', style: GoogleFonts.syne(color: EmobiesTheme.muted))),
              )
            else
              ...active.take(5).map((c) => _activeCard(c)),
          ],
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

  Widget _pendingCard(ComplaintModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        border: Border.all(color: EmobiesTheme.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.deviceModel, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: EmobiesTheme.text)),
                Text(c.customerPhone, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
                Text(c.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: EmobiesTheme.text2)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.supervisorAssign, arguments: c.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: EmobiesTheme.orange,
              minimumSize: const Size(70, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text('Assign', style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _activeCard(ComplaintModel c) {
    final color = _statusColor(c.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        border: Border.all(color: color.withOpacity(0.2)),
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
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(c.statusDisplay, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _actionBtn(Icons.local_shipping_outlined, 'Track', () {
                Navigator.of(context).pushNamed(AppRoutes.supervisorTracking, arguments: c.assignedDeliveryBoyId);
              }),
              const SizedBox(width: 8),
              _actionBtn(Icons.chat_outlined, 'Chat', () {
                Navigator.of(context).pushNamed(AppRoutes.supervisorChat, arguments: {
                  'chatId': c.id,
                  'title': c.deviceModel,
                  'participants': [c.customerId, c.assignedDeliveryBoyId, c.assignedServiceCenterId].whereType<String>().toList(),
                });
              }),
              const SizedBox(width: 8),
              _actionBtn(Icons.image_outlined, 'Photos', () {
                final imgs = [...?c.imagesBefore, ...?c.imagesAfter, ...?c.deliveryImages];
                Navigator.of(context).pushNamed(AppRoutes.supervisorImages, arguments: imgs);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: EmobiesTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EmobiesTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: EmobiesTheme.orange),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.syne(fontSize: 10, color: EmobiesTheme.text2)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTab() {
    return const StaffManagementScreen(staffList: []);
  }
}