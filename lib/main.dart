import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(EmobiesApp());

class EmobiesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StakingTracker(),
      theme: ThemeData(primarySwatch: Colors.indigo),
    );
  }
}

class StakingTracker extends StatefulWidget {
  @override
  _StakingTrackerState createState() => _StakingTrackerState();
}

class _StakingTrackerState extends State<StakingTracker> {
  final TextEditingController _addressController = TextEditingController();
  String balance = '0';
  String usdValue = '$0';
  List transactions = [];
  bool isLoading = true;

  // നിങ്ങളുടെ wallet
  final String yourWallet = "0x52B73fc47C156b0Bc68F1FE70de5b3f270Fe25a2";

  @override
  void initState() {
    super.initState();
    _addressController.text = yourWallet;
    _fetchWalletData(yourWallet);
  }

  Future<void> _fetchWalletData(String address) async {
    setState(() => isLoading = true);
    
    try {
      final url = 'https://api.etherscan.io/api?module=account&action=balance&address=$address&tag=latest';
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);
      
      final weiBalance = int.parse(data['result']);
      final ethBalance = weiBalance / 1000000000000000000;
      setState(() {
        balance = ethBalance.toStringAsFixed(6) + ' ETH';
        usdValue = '$${(ethBalance * 1958.77).toStringAsFixed(0)}';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        balance = 'API Error';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emobies Staking', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Card(
                  elevation: 8,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(usdValue, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        SizedBox(height: 8),
                        Text(balance, style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                        SizedBox(height: 4),
                        Text('+0.10%', style: TextStyle(color: Colors.green, fontSize: 16)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Wallet Search
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Wallet Address',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () => _fetchWalletData(_addressController.text),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Staking Info
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Staking Stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('• Beacon Depositor (Your wallet)', style: TextStyle(color: Colors.grey[600])),
                        Text('• 3-5% APR expected yield', style: TextStyle(color: Colors.grey[600])),
                        Text('• Kraken funded • 1,957 ETH', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
