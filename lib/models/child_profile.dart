import 'app_rule.dart';
import 'screen_time_schedule.dart';
import 'alert_log.dart';

class ChildProfile {
  final int id;
  final String parentId;
  String fullName;
  int age;
  String? avatarUrl;
  String deviceName;
  String deviceModel;
  String pairingCode;
  String childUsername;
  String childPassword;
  int batteryLevel;
  bool isOnline;
  bool isLocked;
  double lastKnownLat;
  double lastKnownLng;
  double currentNoiseDb;
  double currentEyeDistanceCm;
  DateTime updatedAt;

  List<AppRule> appRules;
  List<ScreenTimeSchedule> schedules;
  List<AlertLog> alertLogs;

  ChildProfile({
    required this.id,
    required this.parentId,
    required this.fullName,
    required this.age,
    this.avatarUrl,
    required this.deviceName,
    required this.deviceModel,
    required this.pairingCode,
    this.childUsername = '',
    this.childPassword = 'Password123@',
    this.batteryLevel = 85,
    this.isOnline = true,
    this.isLocked = false,
    this.lastKnownLat = 10.762622,
    this.lastKnownLng = 106.660172,
    this.currentNoiseDb = 45.0,
    this.currentEyeDistanceCm = 35.0,
    required this.updatedAt,
    this.appRules = const [],
    this.schedules = const [],
    this.alertLogs = const [],
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    var rawRules = json['appRules'] as List?;
    var rawSchedules = json['schedules'] as List?;
    var rawAlerts = json['alertLogs'] as List?;

    return ChildProfile(
      id: json['id'] ?? 0,
      parentId: json['parentId'] ?? '',
      fullName: json['fullName'] ?? '',
      age: json['age'] ?? 8,
      avatarUrl: json['avatarUrl'],
      deviceName: json['deviceName'] ?? 'Android Phone',
      deviceModel: json['deviceModel'] ?? 'Emulator',
      pairingCode: json['pairingCode'] ?? '178701',
      childUsername: json['childUsername'] ?? '',
      childPassword: json['childPassword'] ?? 'Password123@',
      batteryLevel: json['batteryLevel'] ?? 85,
      isOnline: json['isOnline'] ?? true,
      isLocked: json['isLocked'] ?? false,
      lastKnownLat: (json['lastKnownLat'] as num?)?.toDouble() ?? 10.762622,
      lastKnownLng: (json['lastKnownLng'] as num?)?.toDouble() ?? 106.660172,
      currentNoiseDb: (json['currentNoiseDb'] as num?)?.toDouble() ?? 45.0,
      currentEyeDistanceCm: (json['currentEyeDistanceCm'] as num?)?.toDouble() ?? 35.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      appRules: rawRules != null
          ? rawRules.map((e) => AppRule.fromJson(e)).toList()
          : [],
      schedules: rawSchedules != null
          ? rawSchedules.map((e) => ScreenTimeSchedule.fromJson(e)).toList()
          : [],
      alertLogs: rawAlerts != null
          ? rawAlerts.map((e) => AlertLog.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'fullName': fullName,
      'age': age,
      'avatarUrl': avatarUrl,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'pairingCode': pairingCode,
      'childUsername': childUsername,
      'childPassword': childPassword,
      'batteryLevel': batteryLevel,
      'isOnline': isOnline,
      'isLocked': isLocked,
      'lastKnownLat': lastKnownLat,
      'lastKnownLng': lastKnownLng,
      'currentNoiseDb': currentNoiseDb,
      'currentEyeDistanceCm': currentEyeDistanceCm,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
