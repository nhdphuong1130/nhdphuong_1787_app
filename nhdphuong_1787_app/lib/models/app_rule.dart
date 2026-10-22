class AppRule {
  final int id;
  final int childProfileId;
  String appName;
  String packageNameOrDomain;
  String category;
  String status; // Blocked, Limited, Allowed
  int dailyLimitMinutes;
  int usedMinutesToday;
  bool isActive;

  AppRule({
    required this.id,
    required this.childProfileId,
    required this.appName,
    this.packageNameOrDomain = '',
    required this.category,
    required this.status,
    this.dailyLimitMinutes = 45,
    this.usedMinutesToday = 0,
    this.isActive = true,
  });

  factory AppRule.fromJson(Map<String, dynamic> json) {
    return AppRule(
      id: json['id'] ?? 0,
      childProfileId: json['childProfileId'] ?? 0,
      appName: json['appName'] ?? '',
      packageNameOrDomain: json['packageNameOrDomain'] ?? '',
      category: json['category'] ?? 'Entertainment',
      status: json['status'] ?? 'Limited',
      dailyLimitMinutes: json['dailyLimitMinutes'] ?? 45,
      usedMinutesToday: json['usedMinutesToday'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childProfileId': childProfileId,
      'appName': appName,
      'packageNameOrDomain': packageNameOrDomain,
      'category': category,
      'status': status,
      'dailyLimitMinutes': dailyLimitMinutes,
      'usedMinutesToday': usedMinutesToday,
      'isActive': isActive,
    };
  }
}
