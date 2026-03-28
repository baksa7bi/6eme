import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_drawer.dart';

class DeliveryDashboardPage extends StatefulWidget {
  const DeliveryDashboardPage({super.key});

  @override
  State<DeliveryDashboardPage> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<OrderProvider>().fetchOrders(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      type: 'delivery',
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final orderProvider = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final orders = orderProvider.orders;

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Livraisons du Café'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('all', 'Tous'),
                _filterChip('En attente', 'Nouvelles (En attente)'),
                _filterChip('En route', 'Mes Trajets (En route)'),
                _filterChip('Livré par livreur', 'Livrées'),
              ],
            ),
          ),
        ),
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildDeliveryCard(order, orderProvider);
                  },
                ),
    );
  }

  Widget _filterChip(String value, String label) {
    bool isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() => _selectedStatus = value);
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune livraison pour le moment',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(OrderItem order, OrderProvider orderProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _statusBadge(order.status),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_pin_circle_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text('Client: ${order.userId}', style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
            if (order.clientPhone != null && order.clientPhone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final phoneUrl = 'tel:${order.clientPhone}';
                        try {
                          await launchUrl(Uri.parse(phoneUrl));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de lancer l\'appel.')));
                          }
                        }
                      },
                      child: Text(
                        order.clientPhone!,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: InkWell(
                  onTap: (order.deliveryLocation == null || order.status == 'En attente') ? null : () async {
                    // Coordinates should be in format "lat,lng" 
                    final coords = order.deliveryLocation!.trim();
                    final url = 'https://www.google.com/maps/search/?api=1&query=$coords';
                    try {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir Maps. Vérifiez l\'application.')));
                      }
                    }
                  },
                  child: Text(
                    order.status == 'En attente'
                      ? 'Acceptez la commande pour voir l\'adresse'
                      : (order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty 
                          ? '📍 Client: ${order.deliveryLocation}'
                          : 'Adresse non spécifiée'), 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: (order.deliveryLocation != null && order.status != 'En attente') ? Colors.blue : Colors.grey, 
                      decoration: (order.deliveryLocation != null && order.status != 'En attente') ? TextDecoration.underline : null
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM HH:mm').format(order.dateTime)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Articles :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• ${item.quantity}x ${item.menuItem.name}', style: const TextStyle(fontSize: 13)),
            )),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${order.totalAmount} DH', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                // Render different buttons based on state
                if (order.status == 'En attente')
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await orderProvider.updateStatus(order.id, 'En route');
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande prise en charge !')));
                      }
                    },
                    icon: const Icon(Icons.delivery_dining),
                    label: const Text('Prendre la commande'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: order.status == 'Livré par livreur' ? null : () async {
                      final success = await orderProvider.updateStatus(order.id, 'Livré par livreur');
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Livraison confirmée !')));
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la confirmation')));
                      }
                    },
                    icon: Icon(order.status == 'Livré par livreur' ? Icons.done : Icons.check),
                    label: Text(order.status == 'Livré par livreur' ? 'Livraison effectuée' : 'Confirmer livraison'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (order.status == 'Livré par livreur') ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'En attente') color = Colors.orange;
    if (status == 'En route') color = Colors.blueAccent;
    if (status == 'Livré par livreur') color = Colors.green;
    if (status == 'Livraison reçue') color = Colors.blue;
    if (status == 'Annulée') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
