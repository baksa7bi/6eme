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
import 'orders_page.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _deliveryPollTimer;
  bool _isShowingDeliveryAlert = false;
  final Set<String> _notifiedOrderIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });

    _startDeliveryPollTimer();
    NotificationService.stopAlarm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.stopAlarm();
    }
  }

  void _startDeliveryPollTimer() {
    _deliveryPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.isAuthenticated && (auth.user?.isManager == true || auth.user?.isAdmin == true)) {
          _checkPendingDeliveryOrders();
        }
      }
    });
  }

  Future<void> _checkPendingDeliveryOrders() async {
    if (_isShowingDeliveryAlert) return;
    try {
      final orders = await ApiService.getOrders(status: 'En attente', type: 'delivery');
      
      // Filter out orders we've already notified/shown
      final newOrders = orders.where((o) => !_notifiedOrderIds.contains(o.id)).toList();
      
      if (newOrders.isNotEmpty && mounted) {
        newOrders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        
        // Mark these as notified
        _notifiedOrderIds.addAll(newOrders.map((o) => o.id));

        _isShowingDeliveryAlert = true;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DeliveryOrdersManagerDialog(orders: newOrders),
        );
        _isShowingDeliveryAlert = false;
      }
    } catch (e) {
      // Ignored
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    _deliveryPollTimer?.cancel();
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
              selectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
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

class DeliveryOrdersManagerDialog extends StatefulWidget {
  final List<OrderItem> orders;
  const DeliveryOrdersManagerDialog({super.key, required this.orders});

  @override
  State<DeliveryOrdersManagerDialog> createState() => _DeliveryOrdersManagerDialogState();
}

class _DeliveryOrdersManagerDialogState extends State<DeliveryOrdersManagerDialog> {
  late PageController _pageController;
  late List<OrderItem> _orders;
  int _currentIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.orders);
    _pageController = PageController();
    // NO ALARM HERE: Alarm is only for background notifications.
  }

  @override
  void dispose() {
    // Keep stop() as a safety measure
    NotificationService.stopAlarm();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleOrder(String orderId, String status) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
    // Stop alarm when manager acts on a command
    NotificationService.stopAlarm();

    final success = await ApiService.updateOrderStatus(orderId, status);
    
    if (success && mounted) {
       _orders.removeWhere((o) => o.id == orderId);
       if (_orders.isEmpty) {
         Navigator.pop(context);
       } else {
         if (_currentIndex >= _orders.length) {
            _currentIndex = _orders.length - 1;
         }
         setState(() => _isProcessing = false);
         // Update PageView if there are orders left
         if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentIndex);
         }
       }
    } else {
       setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orders.isEmpty) return const SizedBox.shrink();
    
    final order = _orders[_currentIndex];

    return PopScope(
      canPop: false,
      child: Dialog(
        elevation: 10,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               // Header
               Container(
                 padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     colors: [Colors.red.shade400, Colors.red.shade700],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                 ),
                 child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nouvelle Commande', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          if (_orders.length > 1)
                            Text('${_orders.length} en attente', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_orders.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text('${_currentIndex + 1} / ${_orders.length}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                      ),
                  ],
                 ),
               ),
               
               // Body
               SizedBox(
                 height: 400,
                 child: PageView.builder(
                   controller: _pageController,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: _orders.length,
                   itemBuilder: (context, index) {
                     final o = _orders[index];
                     return SingleChildScrollView(
                       padding: const EdgeInsets.all(20),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Ref #${o.id.length > 6 ? o.id.substring(0,6).toUpperCase() : o.id.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('En attente', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Client Info section
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.blueGrey),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(o.clientName ?? 'Client Inconnu', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                    ],
                                  ),
                                  if (o.clientPhone != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(o.clientPhone!, style: const TextStyle(fontSize: 14))),
                                      ],
                                    ),
                                  ],
                                  if (o.paymentMethod != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(o.paymentMethod == 'online' ? Icons.credit_card : Icons.money, size: 16, color: Colors.blueGrey),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(o.paymentMethod == 'online' ? 'Paiement en ligne' : 'Paiement à la livraison', style: TextStyle(color: o.paymentMethod == 'online' ? Colors.green.shade700 : Colors.indigo.shade700, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  ],
                                ]
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            ...o.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                    child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(item.menuItem.name, style: const TextStyle(fontSize: 14))),
                                  Text('${item.menuItem.price * item.quantity} DH', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            )),
                            const Divider(height: 30, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                                Text('${o.totalAmount} DH', style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 20),
                         ],
                       ),
                     );
                   },
                 ),
               ),
               
               // Actions
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)],
                 ),
                 child: Row(
                   children: [
                     Expanded(
                       child: OutlinedButton(
                         onPressed: _isProcessing ? null : () => _handleOrder(order.id, 'Annulée'),
                         style: OutlinedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 14),
                           side: BorderSide(color: Colors.red.shade400, width: 2),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         child: _isProcessing 
                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2)) 
                           : Text('Refuser', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: ElevatedButton(
                         onPressed: _isProcessing ? null : () => _handleOrder(order.id, 'Confirmée'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.green.shade600,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 14),
                           elevation: 0,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         child: _isProcessing 
                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                           : const Text('Accepter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       ),
                     ),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
