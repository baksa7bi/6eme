import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  String _deliveryAddress = '';
  String _deliveryInstructions = '';
  String? _selectedAgencyId;

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);
  String get deliveryAddress => _deliveryAddress;
  String get deliveryInstructions => _deliveryInstructions;
  String? get selectedAgencyId => _selectedAgencyId;

  void addItem(MenuItem menuItem) {
    final existingIndex = _items.indexWhere((item) => item.menuItem.id == menuItem.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.removeWhere((item) => item.menuItem.id == menuItemId);
    notifyListeners();
  }

  void updateQuantity(String menuItemId, int quantity) {
    final index = _items.indexWhere((item) => item.menuItem.id == menuItemId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void updateSpecialInstructions(String menuItemId, String instructions) {
    final index = _items.indexWhere((item) => item.menuItem.id == menuItemId);
    if (index >= 0) {
      _items[index].specialInstructions = instructions;
      notifyListeners();
    }
  }

  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void setDeliveryInstructions(String instructions) {
    _deliveryInstructions = instructions;
    notifyListeners();
  }

  void setAgencyId(String? id) {
    _selectedAgencyId = id;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _deliveryAddress = '';
    _deliveryInstructions = '';
    _selectedAgencyId = null;
    notifyListeners();
  }
}
