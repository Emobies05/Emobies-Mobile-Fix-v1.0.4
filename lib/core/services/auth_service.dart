import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';
import '../models/user_model.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'ew_token';
  static const _roleKey = 'ew_role';
  static const _userKey = 'ew_user';
  static const _biometricKey = 'ew_biometric';
  static const _refreshKey = 'ew_refresh';
  static const _lastAttemptKey = 'ew_last_attempt';
  static const _attemptCountKey = 'ew_attempt_count';

  final LocalAuthentication _localAuth = LocalAuthentication();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  String? get token => _currentUser?.emoKey;

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  bool _validatePasswordStrength(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  Future<bool> _checkRateLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAttempt = prefs.getInt(_lastAttemptKey) ?? 0;
    final attemptCount = prefs.getInt(_attemptCountKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastAttempt > 60000) {
      await prefs.setInt(_attemptCountKey, 0);
      return true;
    }

    if (attemptCount >= 5) {
      return false;
    }

    await prefs.setInt(_attemptCountKey, attemptCount + 1);
    await prefs.setInt(_lastAttemptKey, now);
    return true;
  }

  Future<bool> init() async {
    try {
      final storedToken = await _storage.read(key: _tokenKey);
      final storedRefresh = await _storage.read(key: _refreshKey);
      final storedRole = await _storage.read(key: _roleKey);
      final storedUser = await _storage.read(key: _userKey);

      if (storedToken != null && storedUser != null) {
        _currentUser = UserModel.fromJson(jsonDecode(storedUser));
        
        final isValid = await _validateToken(storedToken);
        if (!isValid) {
          if (storedRefresh != null) {
            final refreshed = await _refreshToken(storedRefresh);
            if (refreshed) return true;
          }
          await logout();
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      log('Auth init error: $e');
      return false;
    }
  }

  Future<bool> _validateToken(String token) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBase}/api/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  Future<bool> _refreshToken(String refreshToken) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBase}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _refreshKey, value: data['refresh_token']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    if (!await _checkRateLimit()) {
      return {'success': false, 'error': 'Too many attempts. Try again in 1 minute.'};
    }

    try {
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      final res = await http.post(
        Uri.parse('${AppConstants.apiBase}/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'X-Password-Salt': salt,
        },
        body: jsonEncode({
          'phone': phone,
          'password_hash': hashedPassword,
          'salt': salt,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && data['token'] != null) {
        final role = data['role'] as String? ?? 'customer';
        final userData = data['user'] as Map<String, dynamic>? ?? {};

        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _refreshKey, value: data['refresh_token'] ?? '');
        await _storage.write(key: _roleKey, value: role);
        await _storage.write(key: _userKey, value: jsonEncode(userData));

        _currentUser = UserModel.fromJson(userData);

        return {'success': true, 'role': role};
      }
      return {'success': false, 'error': data['error'] ?? 'Invalid credentials'};
    } catch (e) {
      log('Login error: $e');
      return {'success': false, 'error': 'Cannot reach server. Check connection.'};
    }
  }

  Future<Map<String, dynamic>> staffLogin({
    required String email,
    required String password,
    required String emoKey,
  }) async {
    if (!await _checkRateLimit()) {
      return {'success': false, 'error': 'Too many attempts. Try again in 1 minute.'};
    }

    try {
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      final res = await http.post(
        Uri.parse('${AppConstants.apiBase}/api/staff/login'),
        headers: {
          'Content-Type': 'application/json',
          'X-Password-Salt': salt,
        },
        body: jsonEncode({
          'email': email,
          'password_hash': hashedPassword,
          'salt': salt,
          'emo_key': emoKey,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && data['token'] != null) {
        final role = data['role'] as String? ?? 'staff';
        final userData = data['user'] as Map<String, dynamic>? ?? {};

        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _refreshKey, value: data['refresh_token'] ?? '');
        await _storage.write(key: _roleKey, value: role);
        await _storage.write(key: _userKey, value: jsonEncode(userData));

        _currentUser = UserModel.fromJson(userData);

        return {'success': true, 'role': role};
      }
      return {'success': false, 'error': data['error'] ?? 'Invalid credentials'};
    } catch (e) {
      log('Staff login error: $e');
      return {'success': false, 'error': 'Cannot reach server. Check connection.'};
    }
  }

  Future<Map<String, dynamic>> superAdminLogin({
    required String password,
    required String secretKey,
  }) async {
    if (!await _checkRateLimit()) {
      return {'success': false, 'error': 'Too many attempts. Try again in 1 minute.'};
    }

    try {
      final res = await http.post(
        Uri.parse('${AppConstants.apiBase}/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'password': password,
          'secret_key': secretKey,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && data['token'] != null) {
        final role = 'super_admin';
        final userData = data['user'] as Map<String, dynamic>? ?? {};

        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _refreshKey, value: data['refresh_token'] ?? '');
        await _storage.write(key: _roleKey, value: role);
        await _storage.write(key: _userKey, value: jsonEncode(userData));

        _currentUser = UserModel.fromJson(userData);

        return {'success': true, 'role': role};
      }
      return {'success': false, 'error': data['error'] ?? 'Invalid credentials'};
    } catch (e) {
      log('Super admin login error: $e');
      return {'success': false, 'error': 'Cannot reach server. Check connection.'};
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    if (!_validatePasswordStrength(password)) {
      return {
        'success': false,
        'error': 'Password must be 8+ chars with uppercase, lowercase, number, and special char.'
      };
    }

    try {
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      final res = await http.post(
        Uri.parse('${AppConstants.apiBase}/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'X-Password-Salt': salt,
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'password_hash': hashedPassword,
          'salt': salt,
          'role': 'customer',
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Registration successful'};
      }
      return {'success': false, 'error': data['error'] ?? 'Registration failed'};
    } catch (e) {
      log('SignUp error: $e');
      return {'success': false, 'error': 'Cannot reach server. Check connection.'};
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _biometricKey);
    _currentUser = null;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isAvailable = await _localAuth.isDeviceSupported();
      return canCheck && isAvailable;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason ?? 'Authenticate to access Emobies',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      log('Biometric auth error: $e');
      return false;
    }
  }

  // Alias for backward compatibility
  Future<bool> isBiometricAvailable() => canCheckBiometrics();

  Future<bool> authenticateWithBiometric({String? reason}) => 
      authenticateWithBiometrics(reason: reason);

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.read(key: _tokenKey);
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

}
