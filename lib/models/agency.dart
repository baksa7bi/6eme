class Agency {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final int ordersCount;
  final double totalCommission;

  Agency({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.ordersCount = 0,
    this.totalCommission = 0.0,
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      id: json['id'].toString(),
      name: json['name'],
      contactPerson: json['contact_person'],
      phone: json['phone'],
      email: json['email'],
      ordersCount: json['orders_count'] ?? 0,
      totalCommission: double.parse((json['orders_sum_commission_amount'] ?? 0).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
    };
  }
}
