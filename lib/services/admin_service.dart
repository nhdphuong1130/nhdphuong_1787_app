import 'dart:convert';
import '../config/config_url.dart';
import 'api_client.dart';

class AdminService {
  /// Lấy thống kê toàn hệ thống thời gian thực từ Database
  static Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await ApiClient.get(ConfigUrl.adminStats);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'totalUsers': 0,
      'totalChildren': 0,
      'onlineChildren': 0,
      'lockedChildren': 0,
      'totalRules': 0,
      'totalSchedules': 0,
      'totalAlerts': 0,
    };
  }

  /// Lấy toàn bộ danh sách người dùng và các thiết bị con liên kết
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await ApiClient.get(ConfigUrl.adminUsers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Admin tạo người dùng mới với vai trò chỉ định (Admin / Staff / Customer)
  static Future<bool> createUser({
    required String userName,
    String? email,
    String? fullName,
    String? phoneNumber,
    String password = 'Password123@',
    String role = 'Customer',
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.adminUsers,
        body: {
          'userName': userName,
          'email': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'password': password,
          'role': role,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Admin xóa người dùng và toàn bộ dữ liệu thiết bị liên quan
  static Future<bool> deleteUser(String userId) async {
    try {
      final response = await ApiClient.delete(ConfigUrl.adminUser(userId));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
