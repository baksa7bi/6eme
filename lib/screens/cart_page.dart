import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/coupon.dart';
import '../models/cart_item.dart';
import '../services/location_service.dart';
import 'login_page.dart';
import 'orders_page.dart';
import '../services/api_service.dart';
import '../models/agency.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Coupon> _availableCoupons = [];
  final List<Coupon> _selectedCoupons = [];
  String? _deliveryLocation;
  bool _isLoadingCoupons = false;
  final TextEditingController _locationController = TextEditingController();
  List<Agency> _agencies = [];
  String? _selectedAgencyId;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('API_LOG: Loading initial cart data. IsAuth: ${auth.isAuthenticated}');
    if (!auth.isAuthenticated) return;

    setState(() => _isLoadingCoupons = true);
    
    try {
      final futures = await Future.wait([
        ApiService.getUserCoupons(auth.user!.id),
        if (auth.user!.isAdmin) ApiService.getAgencies() else Future.value([]),
      ]);
      
      setState(() {
        _availableCoupons = (futures[0] as List<Coupon>).where((c) => !c.isUsed).toList();
        if (auth.user!.isAdmin) {
          _agencies = (futures[1] as List<Agency>);
        }
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoadingCoupons = false);
    }
  }

  void _showCouponSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mes Coupons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Sélectionnez un ou plusieurs coupons à utiliser', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(),
              Expanded(
                child: _availableCoupons.isEmpty
                    ? const Center(child: Text('Vous n\'avez aucun coupon disponible.'))
                    : ListView.builder(
                        itemCount: _availableCoupons.length,
                        itemBuilder: (context, index) {
                          final coupon = _availableCoupons[index];
                          final isSelected = _selectedCoupons.any((c) => c.id == coupon.id);
                          return CheckboxListTile(
                            title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${coupon.discountAmount} DH de réduction'),
                            value: isSelected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  _selectedCoupons.add(coupon);
                                } else {
                                  _selectedCoupons.removeWhere((c) => c.id == coupon.id);
                                }
                              });
                              setState(() {}); // Update main UI
                            },
                          );
                        },
                      ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _totalDiscount {
    return _selectedCoupons.fold(0, (sum, c) => sum + c.discountAmount);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    // Group items by cafe
    Map<String, List<CartItem>> itemsByCafe = {};
    for (var item in cart.items) {
      String cafeId = item.menuItem.cafeId;
      if (!itemsByCafe.containsKey(cafeId)) {
        itemsByCafe[cafeId] = [];
      }
      itemsByCafe[cafeId]!.add(item);
    }

    final double subtotal = cart.totalAmount;
    final double finalTotal = (subtotal - _totalDiscount).clamp(0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Votre Panier')),
      body: cart.items.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: itemsByCafe.keys.length,
                    itemBuilder: (context, index) {
                      String cafeId = itemsByCafe.keys.elementAt(index);
                      List<CartItem> cafeItems = itemsByCafe[cafeId]!;
                      String cafeDisplayName = cafeItems.first.menuItem.cafeId != '0' 
                          ? 'Café #$cafeId' // In a real app, you might want to fetch cafe names or store them in MenuItem
                          : 'Café Original';
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Icon(Icons.store, color: theme.primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Provenance : $cafeDisplayName',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          ...cafeItems.map((item) => _buildCartItem(item, cart)),
                          const Divider(),
                        ],
                      );
                    },
                  ),
                ),
                _buildSummarySection(auth, subtotal, finalTotal, theme, cart, itemsByCafe),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Votre panier est vide', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Provider.of<NavigationProvider>(context, listen: false).goToCafes(),
            child: const Text('Aller au Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
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
        leading: CircleAvatar(
          backgroundColor: Colors.brown[50], 
          child: const Icon(Icons.coffee, color: Colors.brown)
        ),
        title: Text(item.menuItem.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${item.menuItem.price} DH x ${item.quantity}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${item.totalPrice} DH', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () {
                      if (item.quantity > 1) {
                        cart.updateQuantity(item.menuItem.id, item.quantity - 1);
                      } else {
                        cart.removeItem(item.menuItem.id);
                      }
                    },
                  ),
                  Text('${item.quantity}'),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => cart.updateQuantity(item.menuItem.id, item.quantity + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(AuthProvider auth, double subtotal, double finalTotal, ThemeData theme, CartProvider cart, Map<String, List<CartItem>> itemsByCafe) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Selected Coupons View
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Coupons utilisés :', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Choisir'),
                onPressed: _showCouponSelection,
              ),
            ],
          ),
          if (_selectedCoupons.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _selectedCoupons.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(c.code, style: const TextStyle(fontSize: 10)),
                    onDeleted: () => setState(() => _selectedCoupons.remove(c)),
                  ),
                )).toList(),
              ),
            ),
          const Divider(),
          if (auth.isAuthenticated && auth.user!.isAdmin && _agencies.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedAgencyId,
              hint: const Text('Agence (optionnel)'),
              decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.business)),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Aucune agence')),
                ..._agencies.map((agency) => DropdownMenuItem(value: agency.id, child: Text(agency.name))),
              ],
              onChanged: (val) => setState(() => _selectedAgencyId = val),
            ),
            const Divider(),
          ],
          
          _summaryRow('Sous-total', '${subtotal.toStringAsFixed(2)} DH'),
          if (_totalDiscount > 0)
            _summaryRow('Réduction', '-${_totalDiscount.toStringAsFixed(2)} DH', color: Colors.green),
          
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Final', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('${finalTotal.toStringAsFixed(2)} DH',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => _handleCheckout(auth, cart, itemsByCafe, finalTotal),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              child: const Text('Commander maintenant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color ?? Colors.grey[600])),
          Text(value, style: TextStyle(color: color, fontWeight: color != null ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  void _handleCheckout(AuthProvider auth, CartProvider cart, Map<String, List<CartItem>> itemsByCafe, double finalTotal) {
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }
    
    if (!auth.user!.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vérifier votre email avant de commander.'), backgroundColor: Colors.orange),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comment souhaitez-vous commander ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _orderTypeBtn(sheetContext, Icons.restaurant, 'Sur place', Colors.orange, () => _processOrders(auth, cart, itemsByCafe, 'onsite'))),
                const SizedBox(width: 16),
                Expanded(child: _orderTypeBtn(sheetContext, Icons.delivery_dining, 'Livraison', Colors.blue, () => _showLocationDialog(auth, cart, itemsByCafe))),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Note : Si votre panier vient de plusieurs cafés, nous créerons une commande pour chaque établissement.', 
              style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeBtn(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showLocationDialog(AuthProvider auth, CartProvider cart, Map<String, List<CartItem>> itemsByCafe) {
    bool isDetecting = false;
    _locationController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 10),
              Text('Lieu de livraison'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Veuillez entrer votre adresse ou utiliser votre position.'),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Adresse complète ou coordonnées GPS',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.map),
                  suffixIcon: isDetecting 
                    ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.blue),
                        onPressed: () async {
                          setDialogState(() => isDetecting = true);
                          final coords = await LocationService.getCurrentCoordinates();
                          if (coords != null) {
                            _locationController.text = coords;
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la détection. Verifiez le GPS.')));
                            }
                          }
                          setDialogState(() => isDetecting = false);
                        },
                      ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La localisation GPS garantit une livraison rapide.',
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
            ElevatedButton(
              onPressed: () {
                if (_locationController.text.trim().isEmpty) return;
                _deliveryLocation = _locationController.text;
                Navigator.pop(context); // Close dialog
                _processOrders(auth, cart, itemsByCafe, 'delivery');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('CONFIRMER'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processOrders(AuthProvider auth, CartProvider cart, Map<String, List<CartItem>> itemsByCafe, String type) async {
    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    int successCount = 0;
    int totalCafeOrders = itemsByCafe.keys.length;
    List<String> couponCodes = _selectedCoupons.map((c) => c.code).toList();

    // Iterate through each cafe group and create a separate order
    for (int i = 0; i < itemsByCafe.keys.length; i++) {
      String cafeId = itemsByCafe.keys.elementAt(i);
      List<CartItem> cafeItems = itemsByCafe[cafeId]!;
      double cafeSubtotal = cafeItems.fold(0, (sum, item) => sum + item.totalPrice);
      bool isFirst = (i == 0);
      
      // Proportionally distribute discount if multiple cafes? 
      // For simplicity, we apply full discount to the first order if possible, or distribute it.
      // But multi-order discount logic is complex. 
      // User said "split cart based on location", so we'll just create N orders.
      // We apply coupons to the first order for now to ensure they are used.
            final orderData = {
          'user_id': auth.user!.id,
          'cafe_id': int.tryParse(cafeId),
          'total_amount': cafeSubtotal - (isFirst ? _totalDiscount : 0),
          'type': type,
          'delivery_location': type == 'delivery' ? _deliveryLocation : null,
          'status': 'En attente',
          'coupon_codes': isFirst ? couponCodes : [],
          'items': cafeItems.map((item) => {
            'menu_item_id': int.tryParse(item.menuItem.id),
            'quantity': item.quantity,
            'price': item.menuItem.price,
          }).toList(),
          if (_selectedAgencyId != null) 'agency_id': _selectedAgencyId,
        };

      final success = await ApiService.createOrder(orderData);
      if (success) successCount++;
    }

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (successCount == totalCafeOrders) {
      cart.clear();
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Succès : $successCount/$totalCafeOrders commandes créées.'))
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commandes validées ! ✅'),
        content: const Text('Vos commandes ont été réparties par établissement. Vous pouvez les suivre dans l\'onglet Mes Commandes.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersPage()));
            },
            child: const Text('Suivre mes commandes'),
          ),
        ],
      ),
    );
  }
}
