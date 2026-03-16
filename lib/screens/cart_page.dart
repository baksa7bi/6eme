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
import '../services/api_service.dart';
import '../models/agency.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _couponController = TextEditingController();
  double _discount = 0.0;
  String? _appliedCouponCode;
  bool _isValidating = false;
  List<Agency> _agencies = [];
  String? _selectedAgencyId;

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  Future<void> _loadAgencies() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated && auth.user!.isAdmin) {
      try {
        final agencies = await ApiService.getAgencies();
        setState(() => _agencies = agencies);
      } catch (e) {
        // Handle error or ignore
      }
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter pour utiliser un coupon')),
      );
      return;
    }

    if (_couponController.text.isEmpty) return;

    setState(() => _isValidating = true);

    try {
      final result = await ApiService.validateCoupon(
        _couponController.text.trim(),
        int.parse(auth.user!.id),
      );

      if (result['valid'] == true) {
        setState(() {
          _discount = double.parse(result['discount_amount'].toString());
          _appliedCouponCode = _couponController.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon appliqué ! -$_discount DH')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Coupon invalide')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la validation du coupon')),
      );
    } finally {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    final double finalTotal = (cart.totalAmount - _discount).clamp(0, double.infinity);

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
                      Navigator.pop(context);
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
                    color: theme.cardColor,
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1))],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Coupon Section
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: InputDecoration(
                                hintText: 'Code Promo',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                enabled: _appliedCouponCode == null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _appliedCouponCode == null
                              ? ElevatedButton(
                                  onPressed: _isValidating ? null : _validateCoupon,
                                  child: _isValidating
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text('Appliquer'),
                                )
                              : TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _discount = 0;
                                      _appliedCouponCode = null;
                                      _couponController.clear();
                                    });
                                  },
                                  child: const Text('Retirer', style: TextStyle(color: Colors.red)),
                                ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Agency Selection for Admin
                      if (auth.isAuthenticated && auth.user!.isAdmin && _agencies.isNotEmpty) ...[
                        const Text('Passer la commande pour une agence :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedAgencyId,
                          hint: const Text('Sélectionner une agence (optionnel)'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Aucune agence')),
                            ..._agencies.map((agency) => DropdownMenuItem(
                              value: agency.id,
                              child: Text(agency.name),
                            )),
                          ],
                          onChanged: (val) => setState(() => _selectedAgencyId = val),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 16),
                      if (_discount > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sous-total'),
                            Text('${cart.totalAmount} DH'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Réduction', style: TextStyle(color: Colors.green)),
                            Text('-$_discount DH', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                        const Divider(),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('${finalTotal.toStringAsFixed(2)} DH',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor)),
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
                            _showOrderTypeChoice(cart, finalTotal);
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

  void _showOrderTypeChoice(CartProvider cart, double finalTotal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Container(
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
                    sheetContext,
                    icon: Icons.restaurant,
                    title: 'Sur place',
                    subtitle: 'Réserver une table',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CafesPage(isSelectionMode: true)));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChoiceCard(
                    sheetContext,
                    icon: Icons.delivery_dining,
                    title: 'Livraison',
                    subtitle: 'À votre domicile',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmDelivery(cart, finalTotal);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChoiceCard(
              sheetContext,
              icon: Icons.payment,
              title: 'Payer en ligne',
              subtitle: 'Visa, Mastercard, CMI',
              color: Colors.green,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CmiPaymentPage(
                      amount: finalTotal,
                      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
                      onResult: (success) {
                        if (success) {
                          // In a real app, you would create the order via API here
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

  Widget _buildChoiceCard(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
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

  void _confirmDelivery(CartProvider cart, double finalTotal) {
    showDialog(
      context: context,
      builder: (contextDialog) => AlertDialog(
        title: const Text('Confirmer la livraison'),
        content: const Text('Votre commande sera livrée à votre adresse enregistrée. Paiement à la réception.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contextDialog), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);

              // Prepare API data
              final List<Map<String, dynamic>> itemsList = cart.items.map((item) {
                return {
                  'menu_item_id': item.menuItem.id,
                  'quantity': item.quantity,
                  'price': item.menuItem.price,
                };
              }).toList();

              final orderData = {
                'user_id': auth.user!.id,
                'total_amount': finalTotal,
                'type': 'delivery',
                'items': itemsList,
                if (_appliedCouponCode != null) 'coupon_code': _appliedCouponCode,
                if (_selectedAgencyId != null) 'agency_id': _selectedAgencyId,
              };

              Navigator.pop(contextDialog); // Close confirm dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
              );

              final success = await ApiService.createOrder(orderData);
              
              if (!mounted) return;
              Navigator.of(context).pop(); // Close loading dialog

              if (success) {
                // Add to local provider for immediate view
                final localOrder = OrderItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  items: List.from(cart.items),
                  totalAmount: finalTotal,
                  dateTime: DateTime.now(),
                  type: OrderType.delivery,
                );
                orderProvider.addOrder(localOrder);
                cart.clear();

                showDialog(
                  context: context,
                  builder: (successContext) => AlertDialog(
                    title: const Text('Succès !'),
                    content: const Text('Votre commande a été ajoutée à vos activités. Félicitations !'),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(successContext).pop();
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OrdersPage()));
                          },
                          child: const Text('Voir mes commandes')),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur lors de la création de la commande')),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

