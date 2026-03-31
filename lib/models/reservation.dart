class Reservation {
  final String id;
  final String cafeId;
  final String cafeName;
  final String userId;
  final DateTime dateTime;
  final int numberOfPeople;
  final String? specialRequests;
  final double depositAmount;
  final String type; // 'table', 'birthday'
  final String status; // pending, confirmed, cancelled
  final String? paymentIntentId;
  final String? clientName;
  final String? clientPhone;

  Reservation({
    required this.id,
    required this.cafeId,
    required this.cafeName,
    required this.userId,
    required this.dateTime,
    required this.numberOfPeople,
    this.specialRequests,
    this.depositAmount = 0.0,
    this.type = 'table',
    this.status = 'pending',
    this.paymentIntentId,
    this.clientName,
    this.clientPhone,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'].toString(),
      cafeId: json['cafe_id']?.toString() ?? json['cafeId']?.toString() ?? json['cafe']?['id']?.toString() ?? '',
      cafeName: json['cafe_name'] ?? json['cafeName'] ?? json['cafe']?['name'] ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      dateTime: DateTime.parse(json['date_time'] ?? json['dateTime']),
      numberOfPeople: int.tryParse(json['number_of_people']?.toString() ?? json['numberOfPeople']?.toString() ?? '0') ?? 0,
      specialRequests: json['special_requests'] ?? json['specialRequests'],
      depositAmount: double.tryParse(json['deposit_amount']?.toString() ?? json['depositAmount']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? 'table',
      status: json['status'] ?? 'pending',
      paymentIntentId: json['payment_intent_id'] ?? json['paymentIntentId'],
      clientName: json['user']?['name']?.toString(),
      clientPhone: json['user']?['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cafeId': cafeId,
      'cafeName': cafeName,
      'userId': userId,
      'dateTime': dateTime.toIso8601String(),
      'numberOfPeople': numberOfPeople,
      'specialRequests': specialRequests,
      'depositAmount': depositAmount,
      'type': type,
      'status': status,
      'paymentIntentId': paymentIntentId,
    };
  }

  Reservation copyWith({
    String? id,
    String? cafeId,
    String? cafeName,
    String? userId,
    DateTime? dateTime,
    int? numberOfPeople,
    String? specialRequests,
    double? depositAmount,
    String? type,
    String? status,
    String? paymentIntentId,
    String? clientName,
    String? clientPhone,
  }) {
    return Reservation(
      id: id ?? this.id,
      cafeId: cafeId ?? this.cafeId,
      cafeName: cafeName ?? this.cafeName,
      userId: userId ?? this.userId,
      dateTime: dateTime ?? this.dateTime,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      specialRequests: specialRequests ?? this.specialRequests,
      depositAmount: depositAmount ?? this.depositAmount,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
    );
  }

  String get displayType => type == 'birthday' ? 'Anniversaire' : 'Table';
}
