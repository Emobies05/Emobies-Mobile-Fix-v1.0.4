import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final _locationController = StreamController<LatLng>.broadcast();
  Stream<LatLng> get locationStream => _locationController.stream;

  LatLng? _lastLocation;
  LatLng? get lastLocation => _lastLocation;

  // Check and request permissions
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current position (one-time)
  Future<LatLng?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastLocation = LatLng(position.latitude, position.longitude);
      return _lastLocation;
    } catch (e) {
      log('Get position error: $e');
      return null;
    }
  }

  // Start tracking location
  Future<void> startTracking() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    await stopTracking();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10 meters
      ),
    ).listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      _lastLocation = latLng;
      _locationController.add(latLng);
    });
  }

  // Stop tracking
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  // Get address from coordinates (using reverse geocoding via your API)
  Future<String?> getAddress(double lat, double lng) async {
    // This can be implemented using Google Maps Geocoding API
    // or your own backend endpoint
    try {
      // Placeholder for reverse geocoding
      return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    } catch (e) {
      log('Geocoding error: $e');
      return null;
    }
  }

  // Calculate distance between two points in km
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  // Dispose
  void dispose() {
    stopTracking();
    _locationController.close();
  }

  // Get position stream for live tracking
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    );
  }
}

class MapConfig {
  static const CameraPosition defaultCamera = CameraPosition(
    target: LatLng(11.8745, 75.3704), // Kannur, Kerala
    zoom: 15,
  );

  static const MapType mapType = MapType.normal;

  static Set<Marker> createMarkers(List<Map<String, dynamic>> locations) {
    return locations.map((loc) {
      return Marker(
        markerId: MarkerId(loc['id'] ?? 'unknown'),
        position: LatLng(
          loc['lat']?.toDouble() ?? 0.0,
          loc['lng']?.toDouble() ?? 0.0,
        ),
        infoWindow: InfoWindow(
          title: loc['name'] ?? 'Location',
          snippet: loc['status'] ?? '',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          loc['type'] == 'delivery_boy'
              ? BitmapDescriptor.hueOrange
              : loc['type'] == 'customer'
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueBlue,
        ),
      );
    }).toSet();
  }
}