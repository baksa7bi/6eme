import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AdminAgencyVisitsPage extends StatefulWidget {
  const AdminAgencyVisitsPage({super.key});

  @override
  State<AdminAgencyVisitsPage> createState() => _AdminAgencyVisitsPageState();
}

class _AdminAgencyVisitsPageState extends State<AdminAgencyVisitsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _visitsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVisits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadVisits() {
    setState(() {
      _visitsFuture = ApiService.getAgencyVisits();
    });
  }

  // ─── Step 2: Manager approves or rejects the arrival ─────────────────────
  Future<void> _approveVisit(Map<String, dynamic> visit) async {
    final amountController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver l\'arrivée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agence: ${visit['agency']['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Café: ${visit['cafe']['name']}'),
            Text('Touristes: ${visit['tourist_count']}'),
            if (visit['notes'] != null && visit['notes'].isNotEmpty)
              Text('Notes: ${visit['notes']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Montant encaissé (DH)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Entrer le montant dépensé par les touristes',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check),
            label: const Text('Approuver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final amount = double.tryParse(amountController.text) ?? 0.0;

      // Update status to confirmed + set amount
      final statusOk = await ApiService.updateVisitStatus(visit['id'], 'confirmed');
      if (amount > 0) {
        await ApiService.updateVisitSpentAmount(visit['id'], amount);
      }

      if (statusOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrivée approuvée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVisits();
      }
    }
  }

  Future<void> _rejectVisit(Map<String, dynamic> visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter l\'arrivée'),
        content: Text('Rejeter l\'arrivée de ${visit['tourist_count']} touriste(s) '
            'de l\'agence ${visit['agency']['name']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.updateVisitStatus(visit['id'], 'cancelled');
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arrivée rejetée'), backgroundColor: Colors.red),
        );
        _loadVisits();
      }
    }
  }

  // ─── Step 3: Manager confirms payment with proof ──────────────────────────
  Future<void> _handlePayment(Map<String, dynamic> visit) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Commission à payer: ${visit['commission_amount'] ?? 0} DH',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 12),
            const Text('Joindre une preuve de paiement (photo ou PDF):'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'gallery'),
            icon: const Icon(Icons.photo),
            label: const Text('Photo'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Caméra'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      bool success = await ApiService.confirmVisitPayment(
        int.parse(visit['id'].toString()),
        File(image.path),
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement confirmé avec succès! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVisits();
      }
    }
  }

  void _showEditAmountDialog(Map<String, dynamic> visit) {
    final amountController = TextEditingController(
      text: visit['spent_amount']?.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le montant'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: 'Montant total encaissé (DH)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null) {
                final success = await ApiService.updateVisitSpentAmount(visit['id'], amount);
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadVisits();
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visites & Commissions'),
        actions: [IconButton(onPressed: _loadVisits, icon: const Icon(Icons.refresh))],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_empty), text: 'En attente'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Approuvées'),
            Tab(icon: Icon(Icons.paid_outlined), text: 'Payées'),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _visitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];

          final pending = all.where((v) => v['status'] == 'pending').toList();
          final approved = all.where((v) {
            final isPaid = v['confirmed_by_manager'] == 1 || v['confirmed_by_manager'] == true;
            return v['status'] == 'confirmed' && !isPaid;
          }).toList();
          final paid = all.where((v) =>
              v['confirmed_by_manager'] == 1 || v['confirmed_by_manager'] == true).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPendingList(pending),
              _buildApprovedList(approved),
              _buildPaidList(paid),
            ],
          );
        },
      ),
    );
  }

  // ─── Tab 1: Pending approvals ─────────────────────────────────────────────
  Widget _buildPendingList(List<Map<String, dynamic>> visits) {
    if (visits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 60, color: Colors.green),
            SizedBox(height: 12),
            Text('Aucune arrivée en attente', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: visits.length,
      itemBuilder: (_, i) {
        final v = visits[i];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.orange, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        v['agency']['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    _buildBadge('EN ATTENTE', Colors.orange),
                  ],
                ),
                const Divider(),
                _infoRow(Icons.store, 'Café', v['cafe']['name']),
                _infoRow(Icons.people, 'Touristes', '${v['tourist_count']} personnes'),
                _infoRow(Icons.calendar_today, 'Date', v['visit_date'] ?? '-'),
                if (v['notes'] != null && v['notes'].toString().isNotEmpty)
                  _infoRow(Icons.notes, 'Notes', v['notes']),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectVisit(v),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveVisit(v),
                        icon: const Icon(Icons.check),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Tab 2: Approved — awaiting payment ───────────────────────────────────
  Widget _buildApprovedList(List<Map<String, dynamic>> visits) {
    if (visits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_bottom, size: 60, color: Colors.blue),
            SizedBox(height: 12),
            Text('Toutes les commissions ont été réglées', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: visits.length,
      itemBuilder: (_, i) {
        final v = visits[i];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(v['agency']['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _buildBadge('CONFIRMÉE', Colors.blue),
                  ],
                ),
                const Divider(),
                _infoRow(Icons.store, 'Café', v['cafe']['name']),
                _infoRow(Icons.people, 'Touristes', '${v['tourist_count']} personnes'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Montant: ${v['spent_amount'] ?? 0} DH',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Commission (10%): ${v['commission_amount'] ?? 0} DH',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditAmountDialog(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handlePayment(v),
                    icon: const Icon(Icons.payment),
                    label: const Text('Payer la commission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Tab 3: Paid ──────────────────────────────────────────────────────────
  Widget _buildPaidList(List<Map<String, dynamic>> visits) {
    if (visits.isEmpty) {
      return const Center(child: Text('Aucun paiement effectué'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: visits.length,
      itemBuilder: (_, i) {
        final v = visits[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(v['agency']['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${v['cafe']['name']} • ${v['tourist_count']} touristes\n${v['paid_at'] ?? ''}'),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${v['commission_amount'] ?? 0} DH',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('payé', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
