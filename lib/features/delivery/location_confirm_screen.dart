import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';

class LocationConfirmScreen extends StatefulWidget {
  final String type; // 'customer' or 'service_center'
  final String complaintId;

  const LocationConfirmScreen({
    super.key,
    required this.type,
    required this.complaintId,
  });

  @override
  State<LocationConfirmScreen> createState() => _LocationConfirmScreenState();
}

class _LocationConfirmScreenState extends State<LocationConfirmScreen> {
  final _api = ApiService(AuthService());
  final _location = LocationService();
  GoogleMapController? _mapController;
  LatLng? _currentLoc;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final loc = await _location.getCurrentPosition();
    if (loc != null) {
      setState(() => _currentLoc = loc);
    }
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final loc = _location.lastLocation;
      if (loc != null) {
        await _api.updateLocation(loc.latitude, loc.longitude);
      }

      if (widget.type == 'customer') {
        await _api.updateComplaintStatus(widget.complaintId, 'reached_customer');
      } else {
        await _api.updateComplaintStatus(widget.complaintId, 'dropped_sc');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.type == 'customer' ? 'Customer location confirmed!' : 'Service center drop confirmed!',
            style: GoogleFonts.syne(color: EmobiesTheme.green),
          ),
          backgroundColor: EmobiesTheme.card,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _confirming = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.syne(color: EmobiesTheme.red))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'customer' ? 'Reached Customer' : 'Service Center Drop';

    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: _currentLoc == null
                ? const Center(child: CircularProgressIndicator(color: EmobiesTheme.orange))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLoc!,
                      zoom: 17,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: {
                      Marker(
                        markerId: const MarkerId('current'),
                        position: _currentLoc!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EmobiesTheme.surface,
              border: const Border(top: BorderSide(color: EmobiesTheme.border)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_currentLoc != null)
                    Text(
                      '${_currentLoc!.latitude.toStringAsFixed(5)}, ${_currentLoc!.longitude.toStringAsFixed(5)}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: EmobiesTheme.muted),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _currentLoc == null || _confirming ? null : _confirm,
                      child: _confirming
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : Text(
                              widget.type == 'customer' ? 'Confirm: Reached Customer' : 'Confirm: Dropped at SC',
                              style: GoogleFonts.syne(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}