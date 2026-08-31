import 'package:flutter/material.dart';
import '../../config/theme.dart';

class EmocoinScreen extends StatelessWidget {
  const EmocoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        backgroundColor: EmobiesTheme.card,
        title: const Text('EmoCoins', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          '🪙 EmoCoins Coming Soon',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
