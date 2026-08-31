import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/location_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String? deliveryBoyId;
  const DeliveryTrackingScreen({super.key, this.deliveryBoyId});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  GoogleMapController? _mapController;
  final _api = ApiService(AuthService());
  final _location = LocationService();
  LatLng? _deliveryBoyLoc;
  LatLng? _customerLoc;
  bool _loading = true;
  StreamSubscription? _locSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.deliveryBoyId != null) {
        final locData = await _api.getDeliveryBoyLocation(widget.deliveryBoyId!);
        if (locData != null) {
          setState(() {
            _deliveryBoyLoc = LatLng(
              locData['latitude']?.toDouble() ?? 0,
              locData['longitude']?.toDouble() ?? 0,
            );
            _loading = false;
          });
        }

        // Subscribe to live location updates via Supabase realtime
        final supabase = SupabaseService.instance;
        supabase.subscribeToLocation(widget.deliveryBoyId!, (lat, lng) {
          setState(() => _deliveryBoyLoc = LatLng(lat, lng));
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat, lng)),
          );
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(title: const Text('Live Tracking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EmobiesTheme.orange))
          : Column(
              children: [
                // Map
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _deliveryBoyLoc ?? MapConfig.defaultCamera.target,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: {
                      if (_deliveryBoyLoc != null)
                        Marker(
                          markerId: const MarkerId('delivery_boy'),
                          position: _deliveryBoyLoc!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                          infoWindow: const InfoWindow(title: 'Delivery Boy'),
                        ),
                      if (_customerLoc != null)
                        Marker(
                          markerId: const MarkerId('customer'),
                          position: _customerLoc!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          infoWindow: const InfoWindow(title: 'Customer'),
                        ),
                    },
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                  ),
                ),
                // Info Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EmobiesTheme.surface,
                    border: const Border(top: BorderSide(color: EmobiesTheme.border)),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: EmobiesTheme.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Delivery Boy Location', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            if (_deliveryBoyLoc != null)
                              Text(
                                '${_deliveryBoyLoc!.latitude.toStringAsFixed(4)}, ${_deliveryBoyLoc!.longitude.toStringAsFixed(4)}',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: EmobiesTheme.muted),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_deliveryBoyLoc != null) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(_deliveryBoyLoc!, 16),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                            child: Text('Center on Delivery Boy', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
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
    _locSub?.cancel();
    if (widget.deliveryBoyId != null) {
      SupabaseService.instance.unsubscribe('loc_${widget.deliveryBoyId}');
    }
    super.dispose();
  }
}