class AlertLog {
  final int id;
  final int childProfileId;
  final String alertType; // EYE_DISTANCE, NOISE_DANGER, GEOFENCE_OUT
  final String value;
  final String severity; // Warning, Danger, Info
  final String message;
  final DateTime createdAt;

  AlertLog({
    required this.id,
    required this.childProfileId,
    required this.alertType,
    required this.value,
    required this.severity,
    required this.message,
    required this.createdAt,
  });

  factory AlertLog.fromJson(Map<String, dynamic> json) {
    return AlertLog(
      id: json['id'] ?? 0,
      childProfileId: json['childProfileId'] ?? 0,
      alertType: json['alertType'] ?? 'INFO',
      value: json['value'] ?? '',
      severity: json['severity'] ?? 'Warning',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childProfileId': childProfileId,
      'alertType': alertType,
      'value': value,
      'severity': severity,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
