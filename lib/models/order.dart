import 'cart_item.dart';
import 'menu_item.dart';

enum OrderType { delivery, local }

class OrderItem {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime dateTime;
  final OrderType type;
  final String? cafeName;
  final String status;
  final String? agencyId;
  final double? commissionAmount;
  final String? deliveryLocation;

  OrderItem({
    required this.id,
    this.userId = '0',
    required this.items,
    required this.totalAmount,
    required this.dateTime,
    required this.type,
    this.cafeName,
    this.status = 'En attente',
    this.agencyId,
    this.commissionAmount,
    this.deliveryLocation,
  });

  OrderItem copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    double? totalAmount,
    DateTime? dateTime,
    OrderType? type,
    String? cafeName,
    String? status,
    String? agencyId,
    double? commissionAmount,
    String? deliveryLocation,
  }) {
    return OrderItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      cafeName: cafeName ?? this.cafeName,
      status: status ?? this.status,
      agencyId: agencyId ?? this.agencyId,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<CartItem> cartItems = list.map((i) {
      if (i['menu_item_name'] != null) {
        return CartItem(
          menuItem: MenuItem(
            id: i['menu_item_id']?.toString() ?? '0',
            name: i['menu_item_name'],
            price: double.tryParse(i['price']?.toString() ?? '0') ?? 0.0,
            description: '',
            imageUrl: '',
            category: '',
            cafeId: '0',
          ),
          quantity: int.tryParse(i['quantity']?.toString() ?? '1') ?? 1,
        );
      }
      return CartItem.fromJson(i);
    }).toList();

    return OrderItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '0',
      items: cartItems,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      dateTime: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      type: json['type'] == 'delivery' ? OrderType.delivery : OrderType.local,
      status: json['status'] ?? 'En attente',
      cafeName: json['cafe_name'],
      agencyId: json['agency_id']?.toString(),
      commissionAmount: double.tryParse(json['commission_amount']?.toString() ?? '0'),
      deliveryLocation: json['delivery_location'],
    );
  }
}
