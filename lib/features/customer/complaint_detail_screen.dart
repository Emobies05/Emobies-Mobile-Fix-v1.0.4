import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/complaint_model.dart';

class CustomerComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  const CustomerComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<CustomerComplaintDetailScreen> createState() => _CustomerComplaintDetailScreenState();
}

class _CustomerComplaintDetailScreenState extends State<CustomerComplaintDetailScreen> {
  final _api = ApiService(AuthService());
  ComplaintModel? _complaint;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _api.getComplaint(widget.complaintId);
      setState(() { _complaint = c; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return EmobiesTheme.green;
      case 'cancelled': return EmobiesTheme.red;
      case 'pending': return EmobiesTheme.yellow;
      case 'payment_pending': return EmobiesTheme.orange;
      case 'repair_ongoing': return EmobiesTheme.blue;
      default: return EmobiesTheme.blue;
    }
  }

  Widget _buildTimeline() {
    if (_complaint == null) return const SizedBox.shrink();
    final steps = [
      ('Complaint Registered', _complaint!.createdAt, true),
      ('Assigned', _complaint!.assignedDeliveryBoyId != null ? _complaint!.updatedAt : null, _complaint!.assignedDeliveryBoyId != null),
      ('Pickup', _complaint!.pickupTime, _complaint!.pickupTime != null),
      ('At Service Center', _complaint!.dropTime, _complaint!.dropTime != null),
      ('Repair Complete', _complaint!.repairCompleteTime, _complaint!.repairCompleteTime != null),
      ('Payment', _complaint!.isPaid ? _complaint!.updatedAt : null, _complaint!.isPaid),
      ('Delivered', _complaint!.completedTime, _complaint!.completedTime != null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value.$1;
          final time = e.value.$2;
          final done = e.value.$3;
          final isLast = i == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: done ? EmobiesTheme.green : EmobiesTheme.muted.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: done ? EmobiesTheme.green : EmobiesTheme.muted,
                        width: 2,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      color: done ? EmobiesTheme.green.withOpacity(0.3) : EmobiesTheme.muted.withOpacity(0.2),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: done ? EmobiesTheme.text : EmobiesTheme.muted,
                        )),
                    if (time != null)
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(time),
                        style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.muted),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07080B),
        body: Center(child: CircularProgressIndicator(color: EmobiesTheme.orange)),
      );
    }

    if (_complaint == null) {
      return Scaffold(
        backgroundColor: EmobiesTheme.bg,
        appBar: AppBar(title: const Text('Complaint Detail')),
        body: Center(child: Text('Not found', style: GoogleFonts.syne(color: EmobiesTheme.muted))),
      );
    }

    final c = _complaint!;
    final sColor = _statusColor(c.status);

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: Text('#${c.id.substring(0, 8)}'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(c.statusDisplay,
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: sColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: EmobiesTheme.orange,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EmobiesTheme.card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: EmobiesTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.deviceModel,
                        style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                    const SizedBox(height: 6),
                    Text(c.issueDescription,
                        style: const TextStyle(fontSize: 13, color: EmobiesTheme.text2, height: 1.5)),
                    if (c.imeiNumber != null) ...[
                      const SizedBox(height: 8),
                      Text('IMEI: ${c.imeiNumber}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Location
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EmobiesTheme.card,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: EmobiesTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup Address', style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 13, color: EmobiesTheme.orange)),
                    const SizedBox(height: 6),
                    Text(c.address, style: const TextStyle(fontSize: 13, color: EmobiesTheme.text2)),
                    if (c.landmark != null)
                      Text('Landmark: ${c.landmark}', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Cost
              if (c.estimatedCost != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EmobiesTheme.card,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: EmobiesTheme.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimated Cost', style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: EmobiesTheme.text)),
                          Text('₹${c.estimatedCost?.toStringAsFixed(0) ?? '--'}',
                              style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18, color: EmobiesTheme.orange)),
                        ],
                      ),
                      if (c.finalCost != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Final Cost', style: GoogleFonts.syne(fontWeight: FontWeight.w700, color: EmobiesTheme.text)),
                            Text('₹${c.finalCost?.toStringAsFixed(0) ?? '--'}',
                                style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18, color: c.isPaid ? EmobiesTheme.green : EmobiesTheme.orange)),
                          ],
                        ),
                      if (c.isPaid)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: EmobiesTheme.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('✓ PAID',
                              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.green, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _buildTimeline(),
              // Images
              if (c.imagesBefore != null && c.imagesBefore!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Photos', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: EmobiesTheme.text)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: c.imagesBefore!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        c.imagesBefore![i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: EmobiesTheme.surface,
                          child: const Icon(Icons.broken_image, color: EmobiesTheme.muted),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}