import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import '../models/child_profile.dart';
import '../models/app_rule.dart';
import '../models/screen_time_schedule.dart';
import '../models/alert_log.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ChildService {
  // 1. Quản lý Hồ sơ trẻ em
  static Future<List<ChildProfile>> getChildren() async {
    final response = await ApiClient.get(ConfigUrl.childProfiles);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ChildProfile.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ChildProfile?> getChild(int id) async {
    final response = await ApiClient.get(ConfigUrl.childProfile(id));
    if (response.statusCode == 200) {
      return ChildProfile.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  static Future<bool> createChild(ChildProfile child) async {
    final response = await ApiClient.post(
      ConfigUrl.childProfiles,
      body: child.toJson(),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<ChildProfile?> createChildWithResult(ChildProfile child) async {
    final response = await ApiClient.post(
      ConfigUrl.childProfiles,
      body: child.toJson(),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return ChildProfile.fromJson(jsonDecode(response.body));
      } catch (_) {
        return child;
      }
    }
    return null;
  }

  static Future<bool> updateChild(int id, ChildProfile child) async {
    final response = await ApiClient.put(
      ConfigUrl.childProfile(id),
      body: child.toJson(),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteChild(int id) async {
    final response = await ApiClient.delete(ConfigUrl.childProfile(id));
    return response.statusCode == 200;
  }

  static Future<bool> toggleLock(int id) async {
    final response = await ApiClient.post(ConfigUrl.toggleLock(id));
    return response.statusCode == 200;
  }

  // 2. Quản lý Quy tắc App
  static Future<List<AppRule>> getRules(int childId) async {
    final response = await ApiClient.get('${ConfigUrl.appRules}?childId=$childId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AppRule.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> createRule(AppRule rule) async {
    final response = await ApiClient.post(
      ConfigUrl.appRules,
      body: rule.toJson(),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateRule(int id, AppRule rule) async {
    final response = await ApiClient.put(
      ConfigUrl.appRule(id),
      body: rule.toJson(),
    );
    return response.statusCode == 200;
  }

  static Future<bool> toggleRule(int id) async {
    final response = await ApiClient.patch(ConfigUrl.toggleRule(id));
    return response.statusCode == 200;
  }

  static Future<bool> deleteRule(int id) async {
    final response = await ApiClient.delete(ConfigUrl.appRule(id));
    return response.statusCode == 200;
  }

  // 3. Quản lý Lịch biểu
  static Future<List<ScreenTimeSchedule>> getSchedules(int childId) async {
    final response = await ApiClient.get('${ConfigUrl.screenTime}?childId=$childId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ScreenTimeSchedule.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<ScreenTimeSchedule>> getChildSchedules(int childId) async {
    final response = await ApiClient.get('${ConfigUrl.screenTime}/child/$childId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ScreenTimeSchedule.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> createSchedule(ScreenTimeSchedule schedule) async {
    final response = await ApiClient.post(
      ConfigUrl.screenTime,
      body: schedule.toJson(),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteSchedule(int id) async {
    final response = await ApiClient.delete(ConfigUrl.screenTimeItem(id));
    return response.statusCode == 200;
  }

  static Future<bool> toggleSchedule(int id) async {
    final response = await ApiClient.patch('${ConfigUrl.screenTime}/$id/toggle');
    return response.statusCode == 200;
  }

  // 4. Quản lý Cảnh báo
  static Future<List<AlertLog>> getAlerts(int? childId) async {
    String url = ConfigUrl.alertLogs;
    if (childId != null && childId > 0) {
      url += '?childId=$childId';
    }
    final response = await ApiClient.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AlertLog.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> sendAlert(AlertLog alert) async {
    final response = await ApiClient.post(
      ConfigUrl.alertLogs,
      body: alert.toJson(),
    );
    return response.statusCode == 200;
  }

  // 5. Gửi Heartbeat chu kỳ định kỳ (Dành cho máy con đồng bộ lệnh khóa từ xa)
  static Future<Map<String, dynamic>?> sendHeartbeat(
    int childId, {
    int battery = 85,
    double lat = 0.0,
    double lng = 0.0,
    double noiseDb = 45.0,
    double eyeDistanceCm = 35.0,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.heartbeat(childId),
        body: {
          'batteryLevel': battery,
          'lat': lat,
          'lng': lng,
          'noiseDb': noiseDb,
          'eyeDistanceCm': eyeDistanceCm,
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // Hồ sơ bé đã bị xóa trên máy chủ
        return {'isDeleted': true, 'message': 'Hồ sơ bé đã bị xóa khỏi hệ thống'};
      }
    } catch (_) {}
    return null;
  }

  /// Xóa sạch thông tin ghép nối máy trẻ lưu trong SharedPreferences
  static Future<void> clearLocalPairing() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('paired_child_id');
    await prefs.remove('paired_child_name');
    await prefs.remove('paired_code');
  }

  /// Kiểm tra xem hồ sơ của bé còn tồn tại trên máy chủ hay không
  static Future<bool> isChildProfileActive(int childId) async {
    try {
      final res = await sendHeartbeat(childId);
      if (res != null && res['isDeleted'] == true) {
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  // 6. Ghép nối thiết bị máy trẻ bằng PairingCode
  static Future<Map<String, dynamic>> pairDevice({
    required String pairingCode,
    String? deviceName,
    String? deviceModel,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.pairDevice,
        body: {
          'pairingCode': pairingCode,
          'deviceName': deviceName,
          'deviceModel': deviceModel,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, ...data};
      } else {
        try {
          final err = jsonDecode(response.body);
          return {'success': false, 'message': err['message'] ?? 'Mã ghép nối không hợp lệ!'};
        } catch (_) {
          return {'success': false, 'message': 'Không thể ghép nối thiết bị (${response.statusCode})'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 6b. Máy con kiểm tra trạng thái ghép nối realtime bằng PairingCode
  static Future<Map<String, dynamic>?> checkPairStatus(String pairingCode) async {
    try {
      final url = '${ConfigUrl.cleanApiUrl(ConfigUrl.baseUrl)}ChildProfileApi/check-pair/${pairingCode.trim()}';
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // 7. Đăng nhập bằng tài khoản do phụ huynh cấp cho bé
  static Future<Map<String, dynamic>> kidLogin({
    required String username,
    required String password,
    String? deviceName,
    String? deviceModel,
  }) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.kidLogin,
        body: {
          'username': username,
          'password': password,
          'deviceName': deviceName,
          'deviceModel': deviceModel,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, ...data};
      } else {
        try {
          final err = jsonDecode(response.body);
          return {'success': false, 'message': err['message'] ?? 'Tài khoản hoặc mật khẩu bé không đúng!'};
        } catch (_) {
          return {'success': false, 'message': 'Đăng nhập thất bại (${response.statusCode})'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 8. Yêu cầu hủy kết nối (Gửi mã phê duyệt về máy phụ huynh)
  static Future<Map<String, dynamic>> requestUnpair(int childId) async {
    try {
      final response = await ApiClient.post(ConfigUrl.requestUnpair(childId));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, ...data};
      } else {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'Không thể gửi yêu cầu hủy kết nối!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 9. Xác nhận hủy kết nối bằng mã phụ huynh cung cấp
  static Future<Map<String, dynamic>> confirmUnpair(int childId, String otpCode) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.confirmUnpair(childId),
        body: {'otpCode': otpCode},
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, ...data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Mã xác thực phụ huynh không đúng!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 10. Xác thực mật khẩu phụ huynh khi muốn thoát Chế độ Bé
  static Future<Map<String, dynamic>> verifyParentExit(int childId, String password) async {
    try {
      final response = await ApiClient.post(
        ConfigUrl.verifyParentExit(childId),
        body: {'password': password},
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, ...data};
      } else if (response.statusCode == 404) {
        final authRes = await AuthService.login('parent1787', password);
        if (authRes['success'] == true || authRes['requiresOtp'] == true) {
          return {'success': true, 'message': 'Xác thực phụ huynh thành công!'};
        }
        return {'success': false, 'message': 'Mật khẩu phụ huynh không chính xác!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Mật khẩu phụ huynh không chính xác!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ xác thực: $e'};
    }
  }
}
