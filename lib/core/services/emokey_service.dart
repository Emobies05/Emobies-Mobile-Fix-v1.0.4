import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';

class EmoKeyService {
  static const String _baseUrl = AppConstants.emoKeyBase;

  // Generate new emo key
  Future<String?> generateKey({String? userId, String? deviceId}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/index'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (userId != null) 'user_id': userId,
          if (deviceId != null) 'device_id': deviceId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['emo_key'] as String?;
      }
      log('EmoKey gen error: ${res.statusCode} - ${res.body}');
      return null;
    } catch (e) {
      log('EmoKey generate error: $e');
      return null;
    }
  }

  // Verify emo key
  Future<bool> verifyKey(String key) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emo_key': key}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['valid'] == true;
      }
      return false;
    } catch (e) {
      log('EmoKey verify error: $e');
      return false;
    }
  }

  // Revoke emo key
  Future<bool> revokeKey(String key) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/revoke'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emo_key': key}),
      ).timeout(const Duration(seconds: 8));

      return res.statusCode == 200;
    } catch (e) {
      log('EmoKey revoke error: $e');
      return false;
    }
  }

  // Get key info
  Future<Map<String, dynamic>?> getKeyInfo(String key) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/info?key=$key'),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      log('EmoKey info error: $e');
      return null;
    }
  }
}