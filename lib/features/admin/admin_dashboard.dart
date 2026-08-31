import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _api = ApiService(AuthService());
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await _api.getDashboardStats();
      setState(() { _stats = stats; _loading = false; });
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
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: const Text('Super Admin'),
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
                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _statCard('Total Complaints', '${_stats?['total_complaints'] ?? 0}', EmobiesTheme.blue, Icons.assignment_outlined),
                        _statCard('Pending', '${_stats?['pending'] ?? 0}', EmobiesTheme.yellow, Icons.pending_actions_outlined),
                        _statCard('Active Repairs', '${_stats?['active'] ?? 0}', EmobiesTheme.orange, Icons.build_outlined),
                        _statCard('Completed', '${_stats?['completed'] ?? 0}', EmobiesTheme.green, Icons.check_circle_outline),
                        _statCard('Revenue', '₹${(_stats?['revenue'] ?? 0).toStringAsFixed(0)}', EmobiesTheme.purple, Icons.currency_rupee),
                        _statCard('Staff', '${_stats?['total_staff'] ?? 0}', EmobiesTheme.cyan, Icons.people_outline),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Quick Actions', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                    const SizedBox(height: 12),
                    _actionCard(Icons.assignment_outlined, 'All Complaints', 'View & manage all complaints', () {
                      Navigator.of(context).pushNamed(AppRoutes.adminComplaints);
                    }),
                    _actionCard(Icons.person_add_outlined, 'Add Staff', 'Add delivery boys & service centers', () {
                      Navigator.of(context).pushNamed(AppRoutes.adminStaffAdd);
                    }),
                    _actionCard(Icons.analytics_outlined, 'Analytics', 'View business analytics', () {
                      Navigator.of(context).pushNamed(AppRoutes.adminAnalytics);
                    }),
                    _actionCard(Icons.chat_outlined, 'Monitor Chats', 'View monitored chat logs', () {}),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
        ],
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EmobiesTheme.card,
          border: Border.all(color: EmobiesTheme.border),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EmobiesTheme.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: EmobiesTheme.orange, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14, color: EmobiesTheme.text)),
                  Text(subtitle, style: GoogleFonts.syne(fontSize: 11, color: EmobiesTheme.text2)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: EmobiesTheme.muted),
          ],
        ),
      ),
    );
  }
}