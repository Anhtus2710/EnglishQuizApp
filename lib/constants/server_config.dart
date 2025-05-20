import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const String _defaultBaseUrl = 'http://192.168.1.105:3000';
  static const String _baseUrlKey = 'base_url';
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';

  /// Lấy base URL hiện tại
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
    print('Base URL retrieved: $baseUrl');
    return baseUrl;
  }

  /// Cập nhật base URL
  static Future<void> setBaseUrl(String url) async {
    if (!Uri.parse(url).isAbsolute) {
      throw Exception('URL không hợp lệ: $url');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
    print('Base URL updated: $url');
  }

  /// Lưu JWT token
  static Future<void> saveToken(String token) async {
    if (token.isEmpty) {
      throw Exception('Token không hợp lệ');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('Token saved');
  }

  /// Lấy JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('Token retrieved: ${token != null ? 'exists' : 'null'}');
    return token;
  }

  /// Lưu userId
  static Future<void> saveUserId(String userId) async {
    if (userId.isEmpty) {
      throw Exception('userId không hợp lệ');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    print('userId saved: $userId');
  }

  /// Lấy userId
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    print('userId retrieved: $userId');
    return userId;
  }

  /// Xóa JWT token và userId
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    print('Token and userId cleared');
  }

  /// Kiểm tra đã đăng nhập hay chưa
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final isLogged = token != null && token.isNotEmpty;
    print('isLoggedIn: $isLogged');
    return isLogged;
  }
}