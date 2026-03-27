import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  // Helper methods to navigate to specific tabs
  void goToHome() => setSelectedIndex(0);
  void goToCafes() => setSelectedIndex(1);
  void goToReservations() => setSelectedIndex(2);
  void goToEvents() => setSelectedIndex(3);
  void goToCart() => setSelectedIndex(4);
}
