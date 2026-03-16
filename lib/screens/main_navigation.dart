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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

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

  final List<Widget> _pages = [
    const HomePage(),
    const CafesPage(),
    const AnniversaryPage(),
    const EventsPage(),
    const CartPage(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return NoInternetPage(onRetry: _checkConnectivity);
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.store),
                label: 'Cafés',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.cake_outlined),
                label: 'Anniversaire',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.event_outlined),
                label: 'Événements',
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
                label: 'Panier',
              ),
            ],
          );
        },
      ),
    );
  }
}
