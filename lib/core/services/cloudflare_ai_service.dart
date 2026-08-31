import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';

class CloudflareAIService {
  static const String _baseUrl = AppConstants.cloudflareAiBase;

  // Emowall AI Chat
  Future<String> chat(String message, {String? emoKey, String? language}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (emoKey != null) 'x-emo-key': emoKey,
      };

      final res = await http.post(
        Uri.parse('$_baseUrl/api/ai'),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'model': 'gemini-2.0-flash',
          'language': language ?? 'auto',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['response'] ?? data['message'] ?? 'No response';
      }
      throw Exception('AI Error: ${res.statusCode}');
    } catch (e) {
      log('Cloudflare AI error: $e');
      return 'Sorry, I\'m having trouble connecting. Please try again later.';
    }
  }

  // Quick AI Summary for dashboard
  Future<String> getDashboardSummary({
    required int activeRepairs,
    required int pendingPayments,
    String? role,
  }) async {
    try {
      final prompt = 'Generate a brief, friendly dashboard summary for Emobies mobile repair app. '
          'Active repairs: $activeRepairs. '
          'Pending payments: ${pendingPayments ?? 0}. '
          'Role: ${role ?? 'user'}. '
          'Keep it under 50 words, motivational tone.';

      return await chat(prompt);
    } catch (e) {
      return 'Welcome back! You have $activeRepairs active repairs.';
    }
  }

  // AI monitoring for service center chat
  Future<Map<String, dynamic>> monitorChat(String message) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/ai/monitor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'check': ['personal_info', 'inappropriate', 'off_topic', 'payment_fraud'],
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'safe': true, 'flags': []};
    } catch (e) {
      log('Monitor error: $e');
      return {'safe': true, 'flags': []};
    }
  }

  // Language detection
  Future<String> detectLanguage(String text) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/ai/lang'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['language'] ?? 'en';
      }
      return 'en';
    } catch (e) {
      return 'en';
    }
  }
}