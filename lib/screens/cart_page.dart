import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import 'login_page.dart';
import 'reservation_page.dart';
import 'orders_page.dart';
import 'cafes_page.dart';
import 'cmi_payment_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Votre Panier')),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Votre panier est vide', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back to menu via bottom nav logic or simple pop if pushed
                      // Here we just let user use bottom nav
                    },
                    child: const Text('Aller au Menu'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Dismissible(
                        key: ValueKey(item.menuItem.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => cart.removeItem(item.menuItem.id),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.coffee)),
                          title: Text(item.menuItem.name),
                          subtitle: Text('${item.menuItem.price} DH x ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${item.totalPrice} DH', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (item.quantity > 1) {
                                    cart.updateQuantity(item.menuItem.id, item.quantity - 1);
                                  } else {
                                    cart.removeItem(item.menuItem.id);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  cart.updateQuantity(item.menuItem.id, item.quantity + 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('${cart.totalAmount} DH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!auth.isAuthenticated) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                              return;
                            }
                            _showOrderTypeChoice(context, cart);
                          },
                          child: const Text('Passer à la commande'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showOrderTypeChoice(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Comment souhaitez-vous commander ?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceCard(
                    context,
                    icon: Icons.restaurant,
                    title: 'Sur place',
                    subtitle: 'Réserver une table',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      // Go to CafesPage to choose a location first, or Reservation directly
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CafesPage(isSelectionMode: true)));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChoiceCard(
                    context,
                    icon: Icons.delivery_dining,
                    title: 'Livraison',
                    subtitle: 'À votre domicile',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelivery(context, cart);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChoiceCard(
              context,
              icon: Icons.payment,
              title: 'Payer en ligne',
              subtitle: 'Visa, Mastercard, CMI',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CmiPaymentPage(
                      amount: cart.totalAmount,
                      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
                      onResult: (success) {
                        if (success) {
                          // Handle success (though currently it's coming soon)
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(15),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _confirmDelivery(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la livraison'),
        content: const Text('Votre commande sera livrée à votre adresse enregistrée. Paiement à la réception.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              
              // Create new order
              final order = OrderItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                items: List.from(cart.items),
                totalAmount: cart.totalAmount,
                dateTime: DateTime.now(),
                type: OrderType.delivery,
              );
              
              orderProvider.addOrder(order);
              cart.clear();
              
              Navigator.pop(context); // Close dialog
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Succès !'),
                  content: const Text('Votre commande a été ajoutée à vos activités.'),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage()));
                      }, 
                      child: const Text('Voir mes commandes')
                    ),
                  ],
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
