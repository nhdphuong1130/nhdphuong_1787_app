import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import 'token_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ConfigUrl.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'requiresOtp': data['requiresOtp'] ?? false,
          'simulatedOtp': data['simulatedOtp'],
          'phoneNumber': data['phoneNumber'],
          'message': data['message'] ?? 'Thành công',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối Web API: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String username, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse(ConfigUrl.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'otpCode': otpCode,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        final token = data['token'];
        await TokenService.saveToken(token);
        final role = await TokenService.getRole() ?? 'Customer';
        return {
          'success': true,
          'token': token,
          'role': role,
          'message': data['message'] ?? 'Xác thực thành công!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Mã OTP không chính xác!',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    String role = 'Customer',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ConfigUrl.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Đăng ký thành công!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng ký thất bại!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<Map<String, dynamic>> resendOtp(String username) async {
    try {
      final response = await http.post(
        Uri.parse(ConfigUrl.resendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'simulatedOtp': data['simulatedOtp'],
        'message': data['message'] ?? 'Đã gửi lại mã OTP.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }
}
