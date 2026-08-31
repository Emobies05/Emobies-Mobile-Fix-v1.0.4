import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloudflare_ai_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/emocoin_model.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _auth = AuthService();
  final _api = ApiService(AuthService());
  final _ai = CloudflareAIService();

  int _tab = 0;
  int _activeRepairs = 0;
  int _coinBalance = 0;
  String _aiSummary = '';
  bool _loading = true;
  List<ComplaintModel> _myComplaints = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _claimDailyCoin();
  }

  Future<void> _loadData() async {
    try {
      final complaints = await _api.getComplaints(
        role: 'customer',
        userId: _auth.currentUser?.id,
      );
      final active = complaints.where((c) =>
        c.status != 'completed' && c.status != 'cancelled'
      ).length;

      final prefs = await SharedPreferences.getInstance();
      final coins = prefs.getInt(AppConstants.prefEmoCoins) ?? 0;

      final summary = await _ai.getDashboardSummary(
        pendingPayments: 0,
        activeRepairs: active,
        role: 'customer',
      );

      setState(() {
        _myComplaints = complaints;
        _activeRepairs = active;
        _coinBalance = coins;
        _aiSummary = summary;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _claimDailyCoin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastClaim = prefs.getString(AppConstants.prefDailyCoinDate);
      final now = DateTime.now();

      if (lastClaim != null) {
        final last = DateTime.parse(lastClaim);
        if (last.year == now.year && last.month == now.month && last.day == now.day) {
          return; // Already claimed today
        }
      }

      final newBalance = (prefs.getInt(AppConstants.prefEmoCoins) ?? 0) + AppConstants.dailyLoginCoins as int;
      await prefs.setInt(AppConstants.prefEmoCoins, newBalance.toInt());
      await prefs.setString(AppConstants.prefDailyCoinDate, now.toIso8601String());

      setState(() => _coinBalance = newBalance.toInt());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+${AppConstants.dailyLoginCoins} EmoCoin claimed! 🎉',
                style: GoogleFonts.syne(color: EmobiesTheme.green)),
            backgroundColor: EmobiesTheme.card,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      body: _loading ? _buildLoading() : _buildBody(),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.registerComplaint),
              backgroundColor: EmobiesTheme.orange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('New Repair', style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: EmobiesTheme.orange));
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0: return _buildDashboard();
      case 1: return _buildComplaintsList();
      case 2: return _buildCoinsTab();
      case 3: return _buildMoreTab();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: RefreshIndicator(
        color: EmobiesTheme.orange,
        backgroundColor: EmobiesTheme.card,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 16),
              if (_aiSummary.isNotEmpty) _buildAiCard(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildRecentComplaints(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, color: EmobiesTheme.text),
                children: const [
                  TextSpan(text: 'E', style: TextStyle(color: EmobiesTheme.orange)),
                  TextSpan(text: 'mobies'),
                ],
              ),
            ),
            Text(
              'Welcome, ${_auth.currentUser?.displayName ?? 'Customer'}',
              style: GoogleFonts.syne(fontSize: 12, color: EmobiesTheme.text2),
            ),
          ],
        ),
        Row(
          children: [
            _iconButton(Icons.chat_bubble_outline, () => Navigator.of(context).pushNamed(AppRoutes.aiChat)),
            const SizedBox(width: 8),
            _iconButton(Icons.logout_outlined, _logout),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: EmobiesTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EmobiesTheme.border),
        ),
        child: Icon(icon, color: EmobiesTheme.text2, size: 20),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('Active Repairs', '$_activeRepairs', EmobiesTheme.orange),
        const SizedBox(width: 10),
        _statCard('EmoCoins', '$_coinBalance', EmobiesTheme.purple),
        const SizedBox(width: 10),
        _statCard('Status', '● Online', EmobiesTheme.green),
      ],
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
            Text(value, style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        border: Border.all(color: EmobiesTheme.purple.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          colors: [EmobiesTheme.purple.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EmobiesTheme.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('🤖 Emowall AI',
                    style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.purple, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_aiSummary, style: const TextStyle(fontSize: 13, color: EmobiesTheme.text2, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionBtn(Icons.build_circle_outlined, 'Repair', EmobiesTheme.orange, () {
              Navigator.of(context).pushNamed(AppRoutes.registerComplaint);
            }),
            const SizedBox(width: 10),
            _actionBtn(Icons.toll_outlined, 'Coins', EmobiesTheme.purple, () {
              setState(() => _tab = 2);
            }),
            const SizedBox(width: 10),
            _actionBtn(Icons.account_balance_wallet_outlined, 'Wallet', EmobiesTheme.green, () {
              Navigator.of(context).pushNamed(AppRoutes.cryptoWallet);
            }),
            const SizedBox(width: 10),
            _actionBtn(Icons.chat_outlined, 'AI Chat', EmobiesTheme.blue, () {
              Navigator.of(context).pushNamed(AppRoutes.aiChat);
            }),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: EmobiesTheme.card,
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.syne(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentComplaints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Repairs', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
        const SizedBox(height: 12),
        if (_myComplaints.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: EmobiesTheme.card, borderRadius: BorderRadius.circular(13)),
            child: Center(
              child: Text('No repairs yet. Start your first!',
                  style: GoogleFonts.syne(fontSize: 13, color: EmobiesTheme.text2)),
            ),
          )
        else
          ..._myComplaints.take(3).map((c) => _complaintTile(c)),
      ],
    );
  }

  Widget _complaintTile(ComplaintModel c) {
    final statusColor = _getStatusColor(c.status);
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.customerComplaintDetail, arguments: c.id),
      child: Container(
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
                  Text(c.deviceModel, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14, color: EmobiesTheme.text)),
                  const SizedBox(height: 4),
                  Text(c.issueDescription, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: EmobiesTheme.text2)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border.all(color: statusColor.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(c.statusDisplay,
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: statusColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return EmobiesTheme.green;
      case 'pending': return EmobiesTheme.yellow;
      case 'cancelled': return EmobiesTheme.red;
      case 'repair_ongoing': return EmobiesTheme.blue;
      case 'payment_pending': return EmobiesTheme.orange;
      default: return EmobiesTheme.blue;
    }
  }

  Widget _buildComplaintsList() {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('My Repairs')),
      body: _myComplaints.isEmpty
          ? Center(child: Text('No repairs yet', style: GoogleFonts.syne(color: EmobiesTheme.muted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myComplaints.length,
              itemBuilder: (_, i) => _complaintTile(_myComplaints[i]),
            ),
    );
  }

  Widget _buildCoinsTab() {
    return EmoCoinWidget(
      balance: _coinBalance,
      onClaim: _claimDailyCoin,
      onExchange: () => Navigator.of(context).pushNamed(AppRoutes.cryptoWallet),
    );
  }

  Widget _buildMoreTab() {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuTile(Icons.person_outline, 'Profile', () {}),
          _menuTile(Icons.security_outlined, 'Security & Biometric', () {
            Navigator.of(context).pushNamed(AppRoutes.biometricSetup);
          }),
          _menuTile(Icons.account_balance_wallet_outlined, 'Crypto Wallet', () {
            Navigator.of(context).pushNamed(AppRoutes.cryptoWallet);
          }),
          _menuTile(Icons.chat_bubble_outline, 'AI Chat Support', () {
            Navigator.of(context).pushNamed(AppRoutes.aiChat);
          }),
          _menuTile(Icons.help_outline, 'Help & Support', () {}),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(backgroundColor: EmobiesTheme.red.withOpacity(0.2)),
              child: Text('Logout', style: GoogleFonts.syne(color: EmobiesTheme.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: EmobiesTheme.orange),
      title: Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w600, color: EmobiesTheme.text)),
      trailing: const Icon(Icons.chevron_right, color: EmobiesTheme.muted),
      onTap: onTap,
    );
  }

  Widget _buildNavBar() {
    return NavigationBar(
      backgroundColor: EmobiesTheme.surface,
      selectedIndex: _tab,
      indicatorColor: EmobiesTheme.orange.withOpacity(0.15),
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: EmobiesTheme.orange), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build, color: EmobiesTheme.orange), label: 'Repairs'),
        NavigationDestination(icon: Icon(Icons.toll_outlined), selectedIcon: Icon(Icons.toll, color: EmobiesTheme.orange), label: 'Coins'),
        NavigationDestination(icon: Icon(Icons.more_horiz_outlined), selectedIcon: Icon(Icons.more_horiz, color: EmobiesTheme.orange), label: 'More'),
      ],
    );
  }
}

// ─── EmoCoin Widget ───
class EmoCoinWidget extends StatelessWidget {
  final int balance;
  final VoidCallback onClaim;
  final VoidCallback onExchange;

  const EmoCoinWidget({
    super.key,
    required this.balance,
    required this.onClaim,
    required this.onExchange,
  });

  @override
  Widget build(BuildContext context) {
    final canExchange = balance >= AppConstants.coinsForCryptoExchange;

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('EmoCoins')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: EmobiesTheme.card,
                border: Border.all(color: EmobiesTheme.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [EmobiesTheme.orange.withOpacity(0.05), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Text('$balance', style: GoogleFonts.syne(fontSize: 48, fontWeight: FontWeight.w800, color: EmobiesTheme.orange)),
                  const SizedBox(height: 4),
                  Text('EmoCoins', style: GoogleFonts.syne(fontSize: 14, color: EmobiesTheme.text2)),
                  const SizedBox(height: 8),
                  Text('≈ ₹${balance * AppConstants.coinRupeeValue.toInt()}', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: EmobiesTheme.muted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(backgroundColor: EmobiesTheme.purple),
                child: Text('+${AppConstants.dailyLoginCoins} Daily Claim', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canExchange ? onExchange : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmobiesTheme.green,
                  disabledBackgroundColor: EmobiesTheme.muted.withOpacity(0.3),
                ),
                child: Text(
                  canExchange ? 'Exchange ${AppConstants.coinsForCryptoExchange}+ for Crypto' : 'Need ${AppConstants.coinsForCryptoExchange} coins',
                  style: GoogleFonts.syne(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...[
              ('📅 Daily Check-in', '+${AppConstants.dailyLoginCoins} coin', EmobiesTheme.blue),
              ('🎰 Scratch Card', '5-50 coins', EmobiesTheme.purple),
              ('👥 Refer Friend', '100 coins', EmobiesTheme.green),
              ('📱 First Repair', '50 coins', EmobiesTheme.orange),
            ].map((item) => _earningOption(item.$1, item.$2, item.$3)),
          ],
        ),
      ),
    );
  }

  Widget _earningOption(String title, String reward, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: EmobiesTheme.text)),
                Text(reward, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color),
        ],
      ),
    );
  }
}