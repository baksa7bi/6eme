import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  String? specialInstructions;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    var menuItemData = json['menuItem'] ?? json['menu_item'];
    return CartItem(
      menuItem: menuItemData != null 
          ? MenuItem.fromJson(menuItemData)
          : MenuItem(id: '0', name: 'Unknown', description: '', price: 0, imageUrl: '', category: '', cafeId: '0'),
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      specialInstructions: json['specialInstructions'] ?? json['special_instructions'],
    );
  }
}
