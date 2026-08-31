import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class CryptoWalletScreen extends StatefulWidget {
  const CryptoWalletScreen({super.key});

  @override
  State<CryptoWalletScreen> createState() => _CryptoWalletScreenState();
}

class _CryptoWalletScreenState extends State<CryptoWalletScreen> {
  final _api = ApiService(AuthService());
  bool _loading = true;
  Map<String, dynamic>? _walletData;
  int _coinBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      // Load coin balance
      final userId = AuthService().currentUser?.id ?? '';
      final coinData = await _api.getCoinBalance(userId);
      setState(() {
        _coinBalance = coinData.balance;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _exchangeCoins() async {
    if (_coinBalance < AppConstants.coinsForCryptoExchange) return;

    setState(() => _loading = true);
    try {
      final userId = AuthService().currentUser?.id ?? '';
      final result = await _api.exchangeCoinsForCrypto(userId, _coinBalance);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Exchange initiated!',
              style: GoogleFonts.syne(color: EmobiesTheme.green)),
          backgroundColor: EmobiesTheme.card,
        ),
      );
      _loadWallet();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exchange failed: $e', style: GoogleFonts.syne(color: EmobiesTheme.red)),
            backgroundColor: EmobiesTheme.card,
          ),
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

    final canExchange = _coinBalance >= AppConstants.coinsForCryptoExchange;

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Crypto Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TheWall Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.orangePurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('TheWall', style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Multi-chain Crypto Wallet', style: GoogleFonts.syne(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Chains
            Row(
              children: [
                _chainCard('Earth', 'ETH', '🔷', EmobiesTheme.blue),
                const SizedBox(width: 8),
                _chainCard('Soul', 'SOL', '◎', EmobiesTheme.purple),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _chainCard('Moon', 'MON', '🌙', EmobiesTheme.cyan),
                const SizedBox(width: 8),
                _chainCard('Orbit', 'ARB', '🔹', EmobiesTheme.blue),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _chainCard('Birth', 'BTC', '₿', EmobiesTheme.yellow),
                const SizedBox(width: 8),
                _chainCard('Base', 'BASE', '⬡', EmobiesTheme.orange),
              ],
            ),
            const SizedBox(height: 24),
            // EmoCoin Exchange
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: EmobiesTheme.card,
                border: Border.all(color: EmobiesTheme.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_coinBalance', style: GoogleFonts.syne(fontSize: 36, fontWeight: FontWeight.w800, color: EmobiesTheme.orange)),
                      const SizedBox(width: 8),
                      Text('EmoCoins', style: GoogleFonts.syne(fontSize: 14, color: EmobiesTheme.text2)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('500 coins = Crypto exchange', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.muted)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: canExchange ? _exchangeCoins : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EmobiesTheme.green,
                        disabledBackgroundColor: EmobiesTheme.muted.withOpacity(0.3),
                      ),
                      child: Text(
                        canExchange ? 'Exchange for Crypto' : 'Need 500 coins',
                        style: GoogleFonts.syne(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chainCard(String name, String symbol, String icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EmobiesTheme.card,
          border: Border.all(color: EmobiesTheme.border),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(name, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 12, color: EmobiesTheme.text)),
            Text(symbol, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}