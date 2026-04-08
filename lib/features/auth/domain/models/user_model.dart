class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' or 'employee'

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      role: map['role'] ?? 'employee',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
    };
  }
}
