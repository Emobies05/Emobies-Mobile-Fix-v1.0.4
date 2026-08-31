import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Overview', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18, color: EmobiesTheme.text)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppGradients.orangePurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Revenue', style: GoogleFonts.syne(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('₹1,24,500', style: GoogleFonts.syne(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('+12% from last month', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _section('Complaint Stats'),
            _statRow('Total Complaints', '156'),
            _statRow('Completion Rate', '87%'),
            _statRow('Avg Repair Time', '2.3 days'),
            _statRow('Customer Satisfaction', '4.6/5'),
            const SizedBox(height: 20),
            _section('Staff Performance'),
            _statRow('Active Delivery Boys', '8'),
            _statRow('Active Service Centers', '3'),
            _statRow('Avg Response Time', '15 min'),
            const SizedBox(height: 20),
            _section('Financial'),
            _statRow('This Month Revenue', '₹45,200'),
            _statRow('Pending Payments', '₹8,400'),
            _statRow('Avg Order Value', '₹1,580'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.orange)),
    );
  }

  Widget _statRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: EmobiesTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EmobiesTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.syne(fontSize: 13, color: EmobiesTheme.text2)),
          Text(value, style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14, color: EmobiesTheme.text)),
        ],
      ),
    );
  }
}