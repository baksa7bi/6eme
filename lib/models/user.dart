class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final String role; // 'client', 'manager', 'admin'

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    this.role = 'client',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      role: json['role'] ?? 'client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'role': role,
    };
  }

  bool get isContentManager => role == 'manager' || role == 'admin';
}
