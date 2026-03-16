import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import '../models/coupon.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_drawer.dart';
import 'main_navigation.dart';

class ManagerCouponsPage extends StatefulWidget {
  const ManagerCouponsPage({super.key});

  @override
  State<ManagerCouponsPage> createState() => _ManagerCouponsPageState();
}

class _ManagerCouponsPageState extends State<ManagerCouponsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<List<Coupon>> _couponsFuture = Future.value([]);
  Future<List<Map<String, dynamic>>> _requestsFuture = Future.value([]);
  int _currentTab = 0; // 0 for coupons, 1 for requests

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  void _loadCoupons() {
    setState(() {
      _couponsFuture = ApiService.getActiveCoupons();
      _requestsFuture = ApiService.getCouponRequests();
    });
  }

  Future<void> _handleApprove(int id) async {
    final success = await ApiService.approveCouponRequest(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande approuvée')));
      _loadCoupons();
    }
  }

  Future<void> _handleReject(int id) async {
    final success = await ApiService.rejectCouponRequest(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande rejetée')));
      _loadCoupons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Coupons Actifs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadCoupons, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentTab = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentTab == 0 ? Colors.orange : Colors.grey[200],
                      foregroundColor: _currentTab == 0 ? Colors.white : Colors.black,
                    ),
                    child: const Text('Coupons Actifs'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentTab = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentTab == 1 ? Colors.orange : Colors.grey[200],
                      foregroundColor: _currentTab == 1 ? Colors.white : Colors.black,
                    ),
                    child: const Text('Demandes'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentTab == 0 ? _buildCouponsList() : _buildRequestsList(),
          ),
        ],
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

  Widget _buildCouponsList() {
    return FutureBuilder<List<Coupon>>(
      future: _couponsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final coupons = snapshot.data ?? [];
        if (coupons.isEmpty) {
          return const Center(child: Text('Aucun coupon actif'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coupons.length,
          itemBuilder: (context, index) => _buildCouponCard(coupons[index]),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data ?? [];
        if (requests.isNotEmpty) {
          debugPrint('DEBUG: First coupon request image URL: ${ApiService.getFullImageUrl(requests.first['image_path'])}');
        }
        if (requests.isEmpty) {
          return const Center(child: Text('Aucune demande en attente'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final bool isPending = req['status'] == 'pending';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text('Demande de: ${req['user']?['name'] ?? 'Inconnu'}'),
                subtitle: Text('Montant: ${req['amount']} DH | Status: ${req['status']} - ${DateFormat('dd/MM HH:mm').format(DateTime.parse(req['created_at']))}'),
                leading: CircleAvatar(
                  backgroundColor: isPending ? Colors.orange : Colors.grey,
                  child: Icon(isPending ? Icons.hourglass_top : Icons.done_all, color: Colors.white),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (req['image_path'] != null)
                          CachedNetworkImage(
                            imageUrl: ApiService.getFullImageUrl(req['image_path']),
                            height: 200,
                            fit: BoxFit.cover,
                            httpHeaders: const {
                              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                            },
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) {
                              debugPrint('IMAGE_LOAD_ERROR: Failed to load image at $url');
                              debugPrint('IMAGE_LOAD_ERROR: Details: $error');
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.broken_image, size: 60, color: Colors.red),
                                  const SizedBox(height: 4),
                                  Text(
                                    error.toString().split('\n').first,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            },
                          ),
                        if (isPending)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => _handleApprove(req['id']),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text('Approuver'),
                              ),
                              ElevatedButton(
                                onPressed: () => _handleReject(req['id']),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                child: const Text('Rejeter'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.card_giftcard, color: Colors.white),
        ),
        title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${coupon.userId}'), // Would be better with user name if available
            Text('Réduction: ${coupon.discountAmount} DH'),
            if (coupon.expiryDate != null)
              Text('Expire le: ${DateFormat('dd/MM/yyyy').format(coupon.expiryDate!)}',
                  style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('VALIDE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}
