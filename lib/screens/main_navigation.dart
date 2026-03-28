import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'home_page.dart';
import 'cafes_page.dart';
import 'cart_page.dart';
import 'reservation_choice_page.dart';
import 'events_page.dart';

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'no_internet_page.dart';
import 'package:store_app/l10n/app_localizations.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import 'email_verification_page.dart';
import 'delivery_dashboard_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  // Scaffold key is now stored in NavigationProvider for global access by child pages

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

  Widget _buildNavigator(int index, int selectedIndex, NavigationProvider navProvider) {
    return Offstage(
      offstage: selectedIndex != index,
      child: Navigator(
        key: navProvider.navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) {
              switch (index) {
                case 0: return const HomePage();
                case 1: return const CafesPage();
                case 2: return const ReservationChoicePage();
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

    final auth = context.watch<AuthProvider>();
    
    // Redirect delivery role to their dashboard
    if (auth.isAuthenticated && auth.user?.isDelivery == true) {
      return const DeliveryDashboardPage();
    }

    // Only block clients who aren't verified. Managers/Admins/etc skip this.
    if (auth.isAuthenticated && auth.user!.isClient && !auth.user!.isEmailVerified) {
      return const EmailVerificationPage();
    }

    final l10n = AppLocalizations.of(context)!;
    final navProvider = Provider.of<NavigationProvider>(context);
    final selectedIndex = navProvider.selectedIndex;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Always close drawer on back button if open
        if (navProvider.mainScaffoldKey.currentState?.isDrawerOpen ?? false) {
          navProvider.mainScaffoldKey.currentState?.closeDrawer();
          return;
        }

        final currentNavigator = navProvider.navigatorKeys[selectedIndex].currentState;
        final isFirstRouteInCurrentTab = !await (currentNavigator?.maybePop() ?? Future.value(false));
        
        if (isFirstRouteInCurrentTab) {
          if (selectedIndex != 0) {
            navProvider.goToHome();
          } else {
            // Exit app if on Home tab root
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        key: navProvider.mainScaffoldKey,
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            _buildNavigator(0, selectedIndex, navProvider),
            _buildNavigator(1, selectedIndex, navProvider),
            _buildNavigator(2, selectedIndex, navProvider),
            _buildNavigator(3, selectedIndex, navProvider),
            _buildNavigator(4, selectedIndex, navProvider),
          ],
        ),
        bottomNavigationBar: Consumer<CartProvider>(
          builder: (context, cart, child) {
            return BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                // Collapse drawer on tab click
                navProvider.mainScaffoldKey.currentState?.closeDrawer();

                if (selectedIndex == index) {
                  // If clicking the active tab, pop all the way to the first route
                  navProvider.navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
                } else {
                  navProvider.setSelectedIndex(index);
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
                  label: l10n.restaurants,
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.date_range_outlined),
                  label: 'Réservation',
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
