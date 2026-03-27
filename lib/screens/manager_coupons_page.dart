import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/coupon.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'app_drawer.dart';

class ManagerCouponsPage extends StatefulWidget {
  const ManagerCouponsPage({super.key});

  @override
  State<ManagerCouponsPage> createState() => _ManagerCouponsPageState();
}

class _ManagerCouponsPageState extends State<ManagerCouponsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Coupon> _allCoupons = [];
  List<Coupon> _filteredCoupons = [];
  List<Map<String, dynamic>> _allRequests = [];
  bool _isLoading = false;
  int _currentTab = 0; // 0 for coupons, 1 for requests
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterCoupons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getActiveCoupons(),
        ApiService.getCouponRequests(),
      ]);
      setState(() {
        _allCoupons = results[0] as List<Coupon>;
        _allRequests = results[1] as List<Map<String, dynamic>>;
        _filterCoupons();
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterCoupons() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCoupons = _allCoupons.where((c) {
        return c.code.toLowerCase().contains(query) || 
               c.userId.toString().contains(query);
      }).toList();
    });
  }

  Future<void> _handleMarkUsed(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'utilisation'),
        content: const Text('Êtes-vous sûr de vouloir marquer ce coupon comme utilisé ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.markCouponAsUsed(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon utilisé avec succès')));
        _loadData();
      }
    }
  }

  Future<void> _handleApprove(int id) async {
    final success = await ApiService.approveCouponRequest(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande approuvée')));
      _loadData();
    }
  }

  Future<void> _handleReject(int id) async {
    final success = await ApiService.rejectCouponRequest(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande rejetée')));
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Gestion Coupons', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  _tabBtn(0, 'Coupons Actifs', Icons.card_giftcard),
                  _tabBtn(1, 'Demandes', Icons.pending_actions),
                ],
              ),
            ),
          ),
          
          if (_currentTab == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un code ou un ID client...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _currentTab == 0 ? _buildCouponsList() : _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(int tab, String label, IconData icon) {
    final isSelected = _currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponsList() {
    if (_filteredCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Aucun coupon trouvé', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCoupons.length,
      itemBuilder: (context, index) => _buildCouponCard(_filteredCoupons[index]),
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.confirmation_num_outlined, color: Colors.white),
        ),
        title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Réduction: ${coupon.discountAmount} DH', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
            Text('Client ID: ${coupon.userId}'),
            if (coupon.expiryDate != null)
              Text('Expire le: ${DateFormat('dd/MM/yyyy').format(coupon.expiryDate!)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _handleMarkUsed(coupon.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[50], 
            foregroundColor: Colors.red,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('UTILISER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_allRequests.isEmpty) {
      return const Center(child: Text('Aucune demande en attente'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allRequests.length,
      itemBuilder: (context, index) {
        final req = _allRequests[index];
        final bool isPending = req['status'] == 'pending';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            title: Text('Demande de: ${req['user']?['name'] ?? 'Inconnu'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${req['amount']} DH | ${req['status']} - ${DateFormat('dd/MM HH:mm').format(DateTime.parse(req['created_at']))}'),
            leading: CircleAvatar(
              backgroundColor: isPending ? Colors.orange : Colors.grey[200],
              child: Icon(isPending ? Icons.hourglass_top : Icons.done_all, color: isPending ? Colors.white : Colors.grey),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (req['image_path'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: ApiService.getFullImageUrl(req['image_path']),
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                        ),
                      ),
                    if (isPending) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleApprove(req['id']),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Approuver'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleReject(req['id']),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: const Text('Rejeter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
