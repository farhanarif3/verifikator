
class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final int phone;
  final String department;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
    required this.department,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      password: json['password'],
      phone: json['phone'],
      department: json['department'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'phone': phone,
      'department': department,
      'role': role,
    };
  }
}
