import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
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
        role: 'customer',
        userId: AuthService().currentUser?.id,
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

  List<ComplaintModel> get _filtered {
    if (_filter == 'all') return _complaints;
    if (_filter == 'active') return _complaints.where((c) => c.status != 'completed' && c.status != 'cancelled').toList();
    if (_filter == 'completed') return _complaints.where((c) => c.status == 'completed').toList();
    return _complaints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: const Text('My Repairs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: EmobiesTheme.orange),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: EmobiesTheme.card,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filter', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 12),
                      _filterOption('All', 'all'),
                      _filterOption('Active', 'active'),
                      _filterOption('Completed', 'completed'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EmobiesTheme.orange))
          : RefreshIndicator(
              color: EmobiesTheme.orange,
              onRefresh: _load,
              child: _filtered.isEmpty
                  ? Center(
                      child: Text('No repairs found', style: GoogleFonts.syne(color: EmobiesTheme.muted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _complaintCard(_filtered[i]),
                    ),
            ),
    );
  }

  Widget _filterOption(String label, String value) {
    final active = _filter == value;
    return ListTile(
      title: Text(label, style: GoogleFonts.syne(color: EmobiesTheme.text)),
      trailing: active ? const Icon(Icons.check, color: EmobiesTheme.orange) : null,
      onTap: () {
        setState(() => _filter = value);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _complaintCard(ComplaintModel c) {
    final color = _statusColor(c.status);
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.customerComplaintDetail,
        arguments: c.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EmobiesTheme.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: EmobiesTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c.deviceModel,
                    style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14, color: EmobiesTheme.text)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(c.statusDisplay,
                      style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.issueDescription, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: EmobiesTheme.text2)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: EmobiesTheme.muted),
                const SizedBox(width: 4),
                Text(
                  '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted),
                ),
                const Spacer(),
                if (c.estimatedCost != null)
                  Text('Est: ₹${c.estimatedCost!.toStringAsFixed(0)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}