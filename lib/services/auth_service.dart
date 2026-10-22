import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_url.dart';
import 'token_service.dart';

class AuthService {
  static Future<http.Response> _postWithFallback(
    String Function() endpointGetter,
    Map<String, dynamic> body,
  ) async {
    try {
      return await http.post(
        Uri.parse(endpointGetter()),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {
      final recovered = await ConfigUrl.autoDiscoverWorkingUrl();
      if (recovered != null) {
        return await http.post(
          Uri.parse(endpointGetter()),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 6));
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _postWithFallback(
        () => ConfigUrl.login,
        {
          'username': username,
          'password': password,
        },
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
      final response = await _postWithFallback(
        () => ConfigUrl.verifyOtp,
        {
          'username': username,
          'otpCode': otpCode,
        },
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
      final response = await _postWithFallback(
        () => ConfigUrl.register,
        {
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': role,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'requiresOtp': data['requiresOtp'] ?? true,
          'username': data['username'] ?? username,
          'phoneNumber': data['phoneNumber'] ?? phoneNumber,
          'message': data['message'] ?? 'Đã gửi mã SMS OTP kích hoạt tài khoản!',
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng ký thất bại!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyRegisterOtp(String username, String otpCode) async {
    try {
      final response = await _postWithFallback(
        () => ConfigUrl.verifyRegisterOtp,
        {
          'username': username,
          'otpCode': otpCode,
        },
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
          'message': data['message'] ?? 'Đăng ký và kích hoạt tài khoản thành công!',
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

  static Future<Map<String, dynamic>> resendRegisterOtp(String username) async {
    try {
      final response = await _postWithFallback(
        () => ConfigUrl.resendRegisterOtp,
        {'username': username},
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Đã gửi lại mã OTP kích hoạt.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  static Future<Map<String, dynamic>> resendOtp(String username) async {
    try {
      final response = await _postWithFallback(
        () => ConfigUrl.resendOtp,
        {'username': username},
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

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await _postWithFallback(
        () => ConfigUrl.googleLogin,
        {'idToken': idToken},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final token = data['token'];
        if (token != null) {
          await TokenService.saveToken(token);
        }
        return {
          'success': true,
          'token': token,
          'role': data['role'] ?? data['user']?['role'] ?? 'Customer',
          'user': data['user'],
          'message': data['message'] ?? 'Đăng nhập Google thành công!',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập Google thất bại!',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }
}
