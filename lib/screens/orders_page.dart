import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import 'app_drawer.dart';
import '../services/api_service.dart';

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Provider.of<NavigationProvider>(context, listen: false).mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(isManager ? 'Gestion Commandes' : 'Mes Commandes'),
        actions: [
          if (isManager)
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Exporter en Excel (mois en cours)',
              onPressed: () => _exportToExcel(),
            ),
        ],
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
            if (isManager) ...[
              Text('Client: ${order.clientName ?? 'Inconnu'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              if (order.clientPhone != null) 
                GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse('tel:${order.clientPhone}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Text('📞 ${order.clientPhone}', style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline)),
                ),
            ],
            Text('${DateFormat('dd/MM/yyyy HH:mm').format(order.dateTime)} • ${order.totalAmount} DH'),
            Text(order.type == OrderType.delivery ? '🛵 Livraison' : '🍽️ Sur place', 
                 style: TextStyle(fontSize: 10, color: order.type == OrderType.delivery ? Colors.blue : Colors.orange)),
            if (order.type == OrderType.delivery && order.paymentMethod != null)
              Text('Paiement: ${order.paymentMethod == 'online' ? '💳 En ligne' : '💵 À la livraison'}', 
                   style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${order.totalAmount} DH', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (!isManager && order.type == OrderType.delivery && order.deliveryId != null) ...[
                   const Divider(),
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.blue[50],
                       borderRadius: BorderRadius.circular(10),
                       border: Border.all(color: Colors.blue[100]!),
                     ),
                     child: Row(
                       children: [
                         const CircleAvatar(
                           radius: 15,
                           backgroundColor: Colors.blue,
                           child: Icon(Icons.person, size: 18, color: Colors.white),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('VOTRE LIVREUR :', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                               Text(order.deliveryName ?? 'Livreur assigné', style: const TextStyle(fontWeight: FontWeight.bold)),
                             ],
                           ),
                         ),
                         if (order.deliveryPhone != null)
                           IconButton(
                             style: IconButton.styleFrom(backgroundColor: Colors.white),
                             icon: const Icon(Icons.phone, color: Colors.green),
                             onPressed: () => launchUrl(Uri.parse('tel:${order.deliveryPhone}')),
                           ),
                       ],
                     ),
                   ),
                ],
                if (!isManager && order.type == OrderType.delivery && order.status != 'Annulée') ...[
                   const Divider(),
                   const Text('Suivi de livraison :', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   _buildDeliveryStepper(order.status),
                ],
                if (!isManager && order.status == 'Livrée' && order.rating == null) ...[
                   const Divider(),
                   const Text('Votre avis sur la livraison :', style: TextStyle(fontWeight: FontWeight.bold)),
                   _buildRatingSelector(order, context),
                ],
                if (order.rating != null) ...[
                   const Divider(),
                    Row(
                      children: [
                        const Text('Ma note: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...List.generate(5, (i) => Icon(
                          Icons.star, 
                          size: 20, 
                          color: i < order.rating! ? Colors.amber : Colors.grey[300]
                        )),
                      ],
                    ),
                    if (order.ratingComment != null && order.ratingComment!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Avis: ${order.ratingComment}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ],
                 ],
                if (order.status == 'Annulée' && order.cancellationReason != null) ...[
                   const Divider(),
                   Text('Raison de l\'annulation: ${order.cancellationReason}', 
                        style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                ],
                if (isManager && order.status == 'En attente') ...[
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
                // Manager can mark a confirmed delivery order as READY
                if (isManager && order.status == 'Confirmée' && order.type == OrderType.delivery) ...[
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await Provider.of<OrderProvider>(context, listen: false)
                            .updateStatus(order.id, 'Prête');
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Commande marquée comme PRÊTE ✅'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marquer comme PRÊTE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
                // Manager can mark a confirmed on-site order as finished
                if (isManager && order.status == 'Confirmée' && order.type == OrderType.local) ...[
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await Provider.of<OrderProvider>(context, listen: false)
                            .updateStatus(order.id, 'Livrée');
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Commande marquée comme terminée !'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Terminer la commande'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
                // Order is confirmed by delivery staff, no client confirmation needed

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
    if (status == 'Prête') return Colors.greenAccent[700]!;
    if (status == 'En route') return Colors.blueAccent;
    if (status == 'Arrivée') return Colors.indigo;
    if (status == 'Livrée') return Colors.green;
    if (status == 'Annulée') return Colors.red;
    return Colors.grey;
  }

  Widget _buildDeliveryStepper(String status) {
    List<Map<String, dynamic>> steps = [
      {'id': 'Confirmée', 'label': 'Confirmé', 'icon': Icons.check},
      {'id': 'Prête', 'label': 'Prêt', 'icon': Icons.restaurant},
      {'id': 'En route', 'label': 'En route', 'icon': Icons.delivery_dining},
      {'id': 'Arrivée', 'label': 'Arrivé', 'icon': Icons.location_on},
      {'id': 'Livrée', 'label': 'Livré', 'icon': Icons.done_all},
    ];

    int currentIdx = -1;
    if (status == 'Confirmée') currentIdx = 0;
    if (status == 'Prête') currentIdx = 1;
    if (status == 'En route') currentIdx = 2;
    if (status == 'Arrivée') currentIdx = 3;
    if (status == 'Livrée') currentIdx = 4;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: steps.map((step) {
        int idx = steps.indexOf(step);
        bool isDone = idx <= currentIdx;
        bool isNext = idx == currentIdx + 1;
        
        return Column(
          children: [
            Icon(
              step['icon'], 
              color: isDone ? Colors.green : (isNext ? Colors.orange : Colors.grey[300]),
              size: 20
            ),
            const SizedBox(height: 4),
            Text(
              step['label'], 
              style: TextStyle(
                fontSize: 8, 
                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                color: isDone ? Colors.black : Colors.grey
              )
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRatingSelector(OrderItem order, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        int starValue = index + 1;
        return IconButton(
          onPressed: () => _showRatingModal(order, starValue),
          icon: Icon(Icons.star_outline, color: Colors.amber[400], size: 30),
        );
      }),
    );
  }

  void _showRatingModal(OrderItem order, int starValue) {
    final TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Donnez votre avis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Icon(
                i < starValue ? Icons.star : Icons.star_outline,
                color: Colors.amber,
              )),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Votre commentaire (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              String? comment = commentController.text.trim();
              if (comment.isEmpty) comment = null;
              
              Navigator.pop(context); // Close modal
              
              final success = await Provider.of<OrderProvider>(context, listen: false)
                  .updateStatus(order.id, 'Livrée', rating: starValue, ratingComment: comment);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Merci pour votre note ! ⭐'))
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _exportToExcel() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final now = DateTime.now();
    
    // Parse the base URL to extract host/port/path
    final baseUri = Uri.parse(ApiService.baseUrl);
    
    final downloadUrl = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: '${baseUri.path}/orders/export',
      queryParameters: {
        'month': now.month.toString(),
        'year': now.year.toString(),
        'token': auth.token ?? '',
      },
    );

    debugPrint('Export URL: $downloadUrl');

    try {
      if (await canLaunchUrl(downloadUrl)) {
        await launchUrl(downloadUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
