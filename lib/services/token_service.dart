import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'jwt_token';
  static const String _userRoleKey = 'user_role';
  static const String _userNameKey = 'user_name';
  static const String _biometricEnabledKey = 'biometric_enabled';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    try {
      final decodedToken = JwtDecoder.decode(token);
      
      // Lấy role từ JWT claims
      dynamic roleClaim = decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] 
                       ?? decodedToken['role'] 
                       ?? 'Customer';

      String role = 'Customer';
      if (roleClaim is List && roleClaim.isNotEmpty) {
        role = roleClaim.first.toString();
      } else if (roleClaim is String) {
        role = roleClaim;
      }
      await prefs.setString(_userRoleKey, role);

      // Lấy username
      String username = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] 
                     ?? decodedToken['unique_name'] 
                     ?? '';
      await prefs.setString(_userNameKey, username);
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null && !JwtDecoder.isExpired(token)) {
      return token;
    }
    return null;
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userNameKey);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }
}
