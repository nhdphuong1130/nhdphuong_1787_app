class ScreenTimeSchedule {
  final int id;
  final int childProfileId;
  String scheduleTitle;
  String dayOfWeek;
  String allowedStartTime;
  String allowedEndTime;
  int maxDailyHours;
  bool isActive;

  ScreenTimeSchedule({
    required this.id,
    required this.childProfileId,
    required this.scheduleTitle,
    required this.dayOfWeek,
    required this.allowedStartTime,
    required this.allowedEndTime,
    this.maxDailyHours = 2,
    this.isActive = true,
  });

  factory ScreenTimeSchedule.fromJson(Map<String, dynamic> json) {
    return ScreenTimeSchedule(
      id: json['id'] ?? 0,
      childProfileId: json['childProfileId'] ?? 0,
      scheduleTitle: json['scheduleTitle'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 'Thứ 2 - Thứ 6',
      allowedStartTime: json['allowedStartTime']?.toString() ?? '19:00:00',
      allowedEndTime: json['allowedEndTime']?.toString() ?? '21:00:00',
      maxDailyHours: json['maxDailyHours'] ?? 2,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childProfileId': childProfileId,
      'scheduleTitle': scheduleTitle,
      'dayOfWeek': dayOfWeek,
      'allowedStartTime': allowedStartTime,
      'allowedEndTime': allowedEndTime,
      'maxDailyHours': maxDailyHours,
      'isActive': isActive,
    };
  }
}
