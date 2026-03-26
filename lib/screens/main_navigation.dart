import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'home_page.dart';
import 'cafes_page.dart';
import 'cart_page.dart';
import 'anniversary_page.dart';
import 'events_page.dart';

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'no_internet_page.dart';

import 'package:store_app/l10n/app_localizations.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // Global Keys for each tab's navigator
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      _isOffline = results.isEmpty || results.every((result) => result == ConnectivityResult.none);
    });
  }

  Widget _buildNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) {
              switch (index) {
                case 0: return const HomePage();
                case 1: return const CafesPage();
                case 2: return const AnniversaryPage();
                case 3: return const EventsPage();
                case 4: return const CartPage();
                default: return const HomePage();
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return NoInternetPage(onRetry: _checkConnectivity);
    }

    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildNavigator(0),
            _buildNavigator(1),
            _buildNavigator(2),
            _buildNavigator(3),
            _buildNavigator(4),
          ],
        ),
        bottomNavigationBar: Consumer<CartProvider>(
          builder: (context, cart, child) {
            return BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (_selectedIndex == index) {
                  // If clicking the active tab, pop all the way to the first route
                  _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
                } else {
                  setState(() => _selectedIndex = index);
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: l10n.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.store),
                  label: l10n.cafes,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.cake_outlined),
                  label: l10n.anniversary,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.event_outlined),
                  label: l10n.events,
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.red,
                            child: Text(
                              '${cart.itemCount}',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        )
                    ],
                  ),
                  label: l10n.cart,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
