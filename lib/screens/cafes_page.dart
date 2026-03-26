import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cafe.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'orders_page.dart';
import 'cafe_detail_page.dart';
import 'package:store_app/l10n/app_localizations.dart';

class CafesPage extends StatelessWidget {
  final bool isSelectionMode;
  const CafesPage({super.key, this.isSelectionMode = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cafes),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // TODO: Open map view
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Cafe>>(
        future: ApiService.getCafes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l10n.error}: ${snapshot.error}'));
          }
          final cafes = snapshot.data ?? [];
          if (cafes.isEmpty) {
            return Center(child: Text(l10n.noCafesFound));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cafes.length,
            itemBuilder: (context, index) {
              return _buildCafeCard(context, cafes[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildCafeCard(BuildContext context, Cafe cafe) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            _confirmLocalOrder(context, cafe);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CafeDetailPage(cafe: cafe),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 180,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: cafe.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiService.getFullImageUrl(cafe.imageUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        httpHeaders: const {
                          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                        },
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) {
                          // Fallback to asset if network fails
                          return Image.asset(
                            'assets/images/cafe.jpg',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/cafe.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).primaryColor.withOpacity(0.7),
                          child: const Center(
                            child: Icon(Icons.local_cafe, size: 60, color: Colors.white70),
                          ),
                        ),
                      ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cafe.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cafe.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        cafe.phone,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        cafe.openingHours.first,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          if (isSelectionMode) {
                            _confirmLocalOrder(context, cafe);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CafeDetailPage(cafe: cafe),
                              ),
                            );
                          }
                        },
                        icon: Icon(isSelectionMode ? Icons.check_circle : Icons.restaurant_menu),
                        label: Text(isSelectionMode ? l10n.chooseThisCafe : l10n.seeMenu),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLocalOrder(BuildContext context, Cafe cafe) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmOrder),
        content: Text(l10n.confirmOrderBody(cafe.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              final cart = Provider.of<CartProvider>(context, listen: false);
              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
              
              final order = OrderItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                items: List.from(cart.items),
                totalAmount: cart.totalAmount,
                dateTime: DateTime.now(),
                type: OrderType.local,
                cafeName: cafe.name,
              );
              
              orderProvider.addOrder(order);
              cart.clear();
              
              Navigator.pop(context); // Close dialog
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.success),
                  content: Text(l10n.orderValidated),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close success dialog
                        // Navigate to orders and remove the selection flow from stack
                        Navigator.pushAndRemoveUntil(
                          context, 
                          MaterialPageRoute(builder: (context) => const OrdersPage()),
                          (route) => route.isFirst,
                        );
                      }, 
                      child: Text(l10n.viewMyOrders)
                    ),
                  ],
                ),
              );
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
