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
                _filterChip('Confirmée', 'Acceptation'),
                _filterChip('Prête', 'Prêtes ✅'),
                _filterChip('En route', 'En route 🛵'),
                _filterChip('Arrivée', 'À destination 📍'),
                _filterChip('Livrée', 'Livrées'),
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
                    return _buildDeliveryCard(order, orderProvider, auth);
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

  Widget _buildDeliveryCard(OrderItem order, OrderProvider orderProvider, AuthProvider auth) {
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
                  onTap: (order.deliveryLocation == null || order.status == 'Confirmée') ? null : () async {
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
                    order.status == 'Confirmée'
                      ? 'Acceptez la commande pour voir l\'adresse'
                      : (order.deliveryLocation != null && order.deliveryLocation!.isNotEmpty 
                          ? '📍 Client: ${order.deliveryLocation}'
                          : 'Adresse non spécifiée'), 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: (order.deliveryLocation != null && order.status != 'Confirmée') ? Colors.blue : Colors.grey, 
                      decoration: (order.deliveryLocation != null && order.status != 'Confirmée') ? TextDecoration.underline : null
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
                
                // --- DYNAMIC ACTIONS: ONLY READY ORDERS CAN BE TAKEN ---
                
                // 1. Order is READY but no one took it yet (Available pool)
                if (order.deliveryId == null && order.status == 'Prête')
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await orderProvider.takeOrder(order.id);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande assignée ! 🛵💨')));
                      }
                    },
                    icon: const Icon(Icons.delivery_dining),
                    label: const Text('Prendre & Partir'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  )
                
                // 2. Assigned to ME AND I can start (already READY)
                else if (order.deliveryId == auth.user?.id.toString() && order.status == 'Prête')
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await orderProvider.updateStatus(order.id, 'En route');
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course démarrée ! 🛵💨')));
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Démarrer la course'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  )
                
                // 3. Trip in progress
                else if (order.status == 'En route')
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await orderProvider.updateStatus(order.id, 'Arrivée');
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arrivée sur place 📍')));
                      }
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Arrivé sur place'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  )
                else if (order.status == 'Arrivée')
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _showCancelDialog(order, orderProvider),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final success = await orderProvider.updateStatus(order.id, 'Livrée');
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Livrée ! 🏁')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Livrée'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(OrderItem order, OrderProvider provider) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la livraison'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Raison de l\'annulation',
            hintText: 'ex: Le client ne répond pas',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              final success = await provider.updateStatus(order.id, 'Annulée', reason: reasonController.text);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Livraison annulée.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'En attente') color = Colors.orange;
    if (status == 'Confirmée') color = Colors.teal;
    if (status == 'Prête') color = Colors.greenAccent[700]!;
    if (status == 'En route') color = Colors.blueAccent;
    if (status == 'Arrivée') color = Colors.indigo;
    if (status == 'Livrée') color = Colors.green;
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
