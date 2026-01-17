import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:get/get.dart';

class TokenService extends GetxService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      Get.log('TokenService initialized', isError: false);
    } catch (e) {
      Get.log('Error initializing SharedPreferences: $e', isError: true);
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  Future<bool> saveToken({
    required String token,
    String? userId,
    String? userRole,
  }) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_tokenKey, token);
      if (userId != null) await prefs.setString(_userIdKey, userId);
      if (userRole != null) await prefs.setString(_userRoleKey, userRole);
      Get.log('Token saved successfully', isError: false);
      return true;
    } catch (e) {
      Get.log('Error saving token: $e', isError: true);
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_tokenKey);
    } catch (e) {
      Get.log('Error getting token: $e', isError: true);
      return null;
    }
  }

  Future<String?> getUserId() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_userRoleKey);
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteToken() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userRoleKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  bool isTokenValid(String token) {
    if (token.contains('static_admin_token') ||
        token.contains('static_college_token')) {
      return true;
    }
    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    return await hasValidToken();
  }

  /// Check if user has any token (alias for hasValidToken for compatibility)
  Future<bool> hasToken() async {
    return await hasValidToken();
  }

  /// Get refresh token from storage
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString('refresh_token');
    } catch (e) {
      Get.log('Error getting refresh token: $e', isError: true);
      return null;
    }
  }

  /// Check if token will expire soon (within 5 minutes)
  Future<bool> willExpireSoon() async {
    try {
      final token = await getToken();
      if (token == null) return true;

      // For static tokens, they never expire
      if (token.contains('static_admin_token') ||
          token.contains('static_college_token')) {
        return false;
      }

      // For real JWT tokens, check if they expire within 5 minutes
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      final fiveMinutesFromNow = now.add(const Duration(minutes: 5));

      return expirationDate.isBefore(fiveMinutesFromNow);
    } catch (e) {
      Get.log('Error checking token expiration: $e', isError: true);
      return true; // Assume it will expire soon if we can't check
    }
  }

  /// Decode JWT token payload
  Map<String, dynamic>? decodeToken(String token) {
    try {
      // For demo static tokens, return mock payload
      if (token.contains('static_admin_token')) {
        return {'sub': 'admin', 'role': 'super_admin', 'exp': 9999999999};
      } else if (token.contains('static_college_token')) {
        return {'sub': 'college', 'role': 'college_admin', 'exp': 9999999999};
      }

      // For real JWT tokens, decode normally
      return JwtDecoder.decode(token);
    } catch (e) {
      Get.log('Error decoding token: $e', isError: true);
      return null;
    }
  }
}
