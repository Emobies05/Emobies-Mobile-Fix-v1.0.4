import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class AllComplaintsScreen extends StatefulWidget {
  const AllComplaintsScreen({super.key});

  @override
  State<AllComplaintsScreen> createState() => _AllComplaintsScreenState();
}

class _AllComplaintsScreenState extends State<AllComplaintsScreen> {
  final _api = ApiService(AuthService());
  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _api.getComplaints(
        status: _filter == 'all' ? null : _filter,
      );
      setState(() { _complaints = list; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
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
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('All Complaints')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', 'all'),
                  _filterChip('Pending', 'pending'),
                  _filterChip('Active', 'active'),
                  _filterChip('Completed', 'completed'),
                  _filterChip('Cancelled', 'cancelled'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: EmobiesTheme.orange))
                : _complaints.isEmpty
                    ? Center(child: Text('No complaints', style: GoogleFonts.syne(color: EmobiesTheme.muted)))
                    : RefreshIndicator(
                        color: EmobiesTheme.orange,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _complaints.length,
                          itemBuilder: (_, i) => _complaintCard(_complaints[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() { _filter = value; _load(); }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? EmobiesTheme.orange.withOpacity(0.15) : EmobiesTheme.card,
          border: Border.all(color: active ? EmobiesTheme.orange : EmobiesTheme.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 11, color: active ? EmobiesTheme.orange : EmobiesTheme.text2)),
      ),
    );
  }

  Widget _complaintCard(ComplaintModel c) {
    final color = _statusColor(c.status);
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminComplaintDetail, arguments: c.id),
      child: Container(
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
                Text('#${c.id.substring(0, 8)}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.muted)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(c.statusDisplay, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.deviceModel, style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14, color: EmobiesTheme.text)),
            Text(c.issueDescription, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: EmobiesTheme.text2)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(c.customerName, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
                const SizedBox(width: 12),
                Text(c.customerPhone, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}