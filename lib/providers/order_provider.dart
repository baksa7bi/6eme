import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<OrderItem> _orders = [];
  bool _isLoading = false;

  List<OrderItem> get orders => [..._orders];
  bool get isLoading => _isLoading;

  Future<void> fetchOrders({String? status, String? type}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getOrders(status: status, type: type);
      _orders = data;
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addOrder(OrderItem order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  Future<bool> updateStatus(String id, String status, {int? rating, String? reason, String? ratingComment}) async {
    try {
      final success = await ApiService.updateOrderStatus(id, status, rating: rating, reason: reason, ratingComment: ratingComment);
      if (success) {
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(
            status: status,
            rating: rating,
            cancellationReason: reason,
            ratingComment: ratingComment,
          );
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
    return false;
  }

  Future<bool> takeOrder(String id) async {
    try {
      final success = await ApiService.takeOrder(id);
      if (success) {
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(status: 'En route');
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error taking order: $e');
    }
    return false;
  }
}
