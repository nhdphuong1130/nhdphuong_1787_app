import 'dart:convert';
import '../config/config_url.dart';
import '../models/child_profile.dart';
import '../models/app_rule.dart';
import '../models/screen_time_schedule.dart';
import '../models/alert_log.dart';
import 'api_client.dart';

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
}
