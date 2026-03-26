import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await ApiService.getNotifications();
      _notifications = results;
      // For now, we use the total count as "unread" until we have a real mark-as-read mechanism
      _unreadCount = _notifications.length; 
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  void addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }
}
