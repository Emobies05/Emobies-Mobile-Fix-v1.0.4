import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../config/constants.dart';
import '../models/complaint_model.dart';
import '../models/emocoin_model.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _auth;
  ApiService(this._auth);

  Future<Map<String, String>> _headers() async {
    return await _auth.getAuthHeaders();
  }

  // Check connectivity
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Generic GET
  Future<dynamic> get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBase}$path'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      log('GET error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Generic POST
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBase}$path'),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      log('POST error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Generic PUT
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await http.put(
        Uri.parse('${AppConstants.apiBase}$path'),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      log('PUT error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Generic PATCH
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await http.patch(
        Uri.parse('${AppConstants.apiBase}$path'),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(res);
    } catch (e) {
      log('PATCH error: $e');
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  // ─── Complaints ───

  Future<List<ComplaintModel>> getComplaints({String? status, String? role, String? userId}) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (role != null) query['role'] = role;
    if (userId != null) query['user_id'] = userId;

    final uri = Uri.parse('${AppConstants.apiBase}/api/complaints').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    final data = _handleResponse(res);
    return (data as List).map((e) => ComplaintModel.fromJson(e)).toList();
  }

  Future<ComplaintModel> getComplaint(String id) async {
    final data = await get('/api/complaints/$id');
    return ComplaintModel.fromJson(data);
  }

  Future<ComplaintModel> createComplaint(Map<String, dynamic> data) async {
    final res = await post('/api/complaints', body: data);
    return ComplaintModel.fromJson(res);
  }

  Future<ComplaintModel> updateComplaintStatus(String id, String status, {Map<String, dynamic>? extra}) async {
    final body = {'status': status, ...?extra};
    final res = await patch('/api/complaints/$id/status', body: body);
    return ComplaintModel.fromJson(res);
  }

  Future<void> assignComplaint(String id, {String? deliveryBoyId, String? serviceCenterId}) async {
    await patch('/api/complaints/$id/assign', body: {
      if (deliveryBoyId != null) 'delivery_boy_id': deliveryBoyId,
      if (serviceCenterId != null) 'service_center_id': serviceCenterId,
    });
  }

  Future<String> uploadImage(File file, {String folder = 'uploads'}) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBase}/api/upload'),
      );
      request.headers.addAll(await _headers());
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      final data = _handleResponse(res);
      return data['url'] as String;
    } catch (e) {
      log('Upload error: $e');
      throw Exception('Upload failed: $e');
    }
  }

  // ─── EmoCoins ───

  Future<EmoCoinModel> getCoinBalance(String userId) async {
    final data = await get('/api/coins/$userId');
    return EmoCoinModel.fromJson(data);
  }

  Future<EmoCoinModel> claimDailyCoins(String userId) async {
    final data = await post('/api/coins/$userId/daily');
    return EmoCoinModel.fromJson(data);
  }

  Future<EmoCoinModel> addCoins(String userId, int amount, String description) async {
    final data = await post('/api/coins/$userId/add', body: {
      'amount': amount,
      'description': description,
    });
    return EmoCoinModel.fromJson(data);
  }

  Future<Map<String, dynamic>> exchangeCoinsForCrypto(String userId, int coins) async {
    return await post('/api/coins/$userId/exchange', body: {
      'coins': coins,
    });
  }

  Future<List<CoinTransaction>> getCoinTransactions(String userId) async {
    final data = await get('/api/coins/$userId/transactions');
    return (data as List).map((e) => CoinTransaction.fromJson(e)).toList();
  }

  // ─── Staff Management ───

  Future<void> addStaff(Map<String, dynamic> data) async {
    await post('/api/staff', body: data);
  }

  Future<void> removeStaff(String id) async {
    await http.delete(
      Uri.parse('${AppConstants.apiBase}/api/staff/$id'),
      headers: await _headers(),
    );
  }

  Future<List<Map<String, dynamic>>> getStaff({String? role}) async {
    final query = role != null ? '?role=$role' : '';
    final data = await get('/api/staff$query');
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ─── Dashboard Stats ───

  Future<Map<String, dynamic>> getDashboardStats() async {
    return await get('/api/dashboard/stats');
  }

  // ─── Location ───

  Future<void> updateLocation(double lat, double lng) async {
    await post('/api/location', body: {
      'lat': lat,
      'lng': lng,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getDeliveryBoyLocation(String id) async {
    return await get('/api/location/$id');
  }
}