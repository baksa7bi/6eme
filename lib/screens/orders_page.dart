import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import 'app_drawer.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _selectedStatus = 'all';
  String _selectedType = 'all';

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
      type: _selectedType == 'all' ? null : _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final orderProvider = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isManager = auth.user?.isManager == true || auth.user?.isAdmin == true;
    final orders = orderProvider.orders;

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(isManager ? 'Gestion Commandes' : 'Mes Commandes'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isManager ? 100 : 50),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip('all', 'Toutes'),
                    _filterChip('active', 'En cours'),
                    _filterChip('history', 'Terminées'),
                    _filterChip('Annulée', 'Annulées'),
                  ],
                ),
              ),
              if (isManager)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _typeChip('all', 'Tout types'),
                      _typeChip('delivery', 'Livraison'),
                      _typeChip('onsite', 'Sur place'),
                    ],
                  ),
                ),
            ],
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
                    return _buildOrderCard(order, isManager);
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

  Widget _typeChip(String value, String label) {
    bool isSelected = _selectedType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
        onSelected: (val) {
          if (val) {
            setState(() => _selectedType = value);
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
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune commande trouvée',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order, bool isManager) {
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
          'Commande #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isManager) Text('Client ID: ${order.userId}'),
            Text('${DateFormat('dd/MM/yyyy HH:mm').format(order.dateTime)} • ${order.totalAmount} DH'),
            Text(order.type == OrderType.delivery ? '🛵 Livraison' : '🍽️ Sur place', 
                 style: TextStyle(fontSize: 10, color: order.type == OrderType.delivery ? Colors.blue : Colors.orange)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            order.status,
            style: TextStyle(color: _getStatusColor(order.status), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Articles :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.menuItem.name}'),
                      Text('${item.menuItem.price * item.quantity} DH'),
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
                if (isManager && order.status == 'En attente' && order.type != OrderType.delivery) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Provider.of<OrderProvider>(context, listen: false).updateStatus(order.id, 'Confirmée'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                        child: const Text('Confirmer'),
                      ),
                      ElevatedButton(
                        onPressed: () => Provider.of<OrderProvider>(context, listen: false).updateStatus(order.id, 'Annulée'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                ],
                if (!isManager && order.status == 'Livré par livreur') ...[
                   const Divider(),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                        onPressed: () => Provider.of<OrderProvider>(context, listen: false).updateStatus(order.id, 'Livraison reçue'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        child: const Text('Confirmer réception'),
                      ),
                   ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'En attente') return Colors.orange;
    if (status == 'Confirmée') return Colors.teal;
    if (status == 'En route') return Colors.blueAccent;
    if (status == 'Livré par livreur') return Colors.green;
    if (status == 'Livraison reçue') return Colors.blue;
    if (status == 'Annulée') return Colors.red;
    return Colors.grey;
  }
}
