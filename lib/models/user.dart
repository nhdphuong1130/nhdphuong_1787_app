class UserModel {
  final String id;
  final String userName;
  final String email;
  final String? fullName;
  final String role;

  UserModel({
    required this.id,
    required this.userName,
    required this.email,
    this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      role: json['role'] ?? json['Role'] ?? 'Customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'fullName': fullName,
      'role': role,
    };
  }
}
