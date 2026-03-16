import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../providers/cart_provider.dart';
import '../models/order.dart';
import 'app_drawer.dart';
import 'main_navigation.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.orders;

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Mes Commandes'),
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune commande pour le moment',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: order.type == OrderType.delivery 
                        ? Colors.blue[100] 
                        : Colors.orange[100],
                      child: Icon(
                        order.type == OrderType.delivery 
                          ? Icons.delivery_dining 
                          : Icons.restaurant,
                        color: order.type == OrderType.delivery 
                          ? Colors.blue 
                          : Colors.orange,
                      ),
                    ),
                    title: Text(
                      'Commande #${order.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy HH:mm').format(order.dateTime)} • ${order.totalAmount} DH',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status,
                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.type == OrderType.local) ...[
                              Text('📍 Établissement: ${order.cafeName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                            ],
                            const Divider(),
                            ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.quantity}x ${item.menuItem.name}'),
                                  Text('${item.totalPrice} DH'),
                                ],
                              ),
                            )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('${order.totalAmount} DH', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return BottomNavigationBar(
            currentIndex: 0,
            onTap: (index) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainNavigation()),
                (route) => false,
              );
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Cafés'),
              const BottomNavigationBarItem(icon: Icon(Icons.cake_outlined), label: 'Anniversaire'),
              const BottomNavigationBarItem(icon: Icon(Icons.event_outlined), label: 'Événements'),
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
                          child: Text('${cart.itemCount}', style: const TextStyle(fontSize: 10, color: Colors.white)),
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
