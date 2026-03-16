import '../models/cart_item.dart';

enum OrderType { delivery, local }

class OrderItem {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime dateTime;
  final OrderType type;
  final String? cafeName; // Only for local
  final String status;
  final String? agencyId;
  final double? commissionAmount;

  OrderItem({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.dateTime,
    required this.type,
    this.cafeName,
    this.status = 'En attente',
    this.agencyId,
    this.commissionAmount,
  });
}
