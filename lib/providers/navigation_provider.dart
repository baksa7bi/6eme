import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;

  // Global key for the ROOT scaffold in MainNavigation (holds the drawer)
  final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

  // Global Keys for each tab's navigator
  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(
    5, 
    (index) => GlobalKey<NavigatorState>()
  );

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  // Push inside the currently active tab
  Future<T?> pushOnCurrentTab<T>(BuildContext context, Widget page) {
    return navigatorKeys[_selectedIndex].currentState!.push<T>(
      MaterialPageRoute(builder: (_) => page)
    );
  }

  // Reset all navigators to root
  void resetAll() {
    for (var key in navigatorKeys) {
      if (key.currentState != null) {
        key.currentState!.popUntil((route) => route.isFirst);
      }
    }
    _selectedIndex = 0;
    notifyListeners();
  }

  // Helper methods to navigate to specific tabs
  void goToHome() => setSelectedIndex(0);
  void goToCafes() => setSelectedIndex(1);
  void goToReservations() => setSelectedIndex(2);
  void goToEvents() => setSelectedIndex(3);
  void goToCart() => setSelectedIndex(4);
}
