import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agency_provider.dart';
import '../services/api_service.dart';
import '../models/cafe.dart';

class AgencyDashboardPage extends StatefulWidget {
  const AgencyDashboardPage({super.key});

  @override
  State<AgencyDashboardPage> createState() => _AgencyDashboardPageState();
}

class _AgencyDashboardPageState extends State<AgencyDashboardPage> {
  late Future<List<Map<String, dynamic>>> _visitsFuture;
  List<Cafe> _cafes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      _visitsFuture = ApiService.getAgencyVisits();
    });
    final cafes = await ApiService.getCafes();
    setState(() {
      _cafes = cafes;
    });
  }

  void _showSubmitVisitDialog() async {
    if (_cafes.isEmpty) {
      final cafes = await ApiService.getCafes();
      setState(() {
        _cafes = cafes;
      });
    }

    if (!mounted) return;

    final countController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedCafeId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Annoncer une Arrivée'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedCafeId,
                    hint: const Text('Sélectionner le Café'),
                    items: _cafes.map((c) => DropdownMenuItem<String>(
                      value: c.id, 
                      child: Text(c.name, overflow: TextOverflow.ellipsis)
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedCafeId = val),
                    decoration: const InputDecoration(
                      labelText: 'Café',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: countController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de touristes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Nationalité',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Annuler', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCafeId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez sélectionner un café'))
                  );
                  return;
                }
                if (countController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer le nombre de touristes'))
                  );
                  return;
                }

                final success = await ApiService.submitAgencyVisit({
                  'cafe_id': selectedCafeId,
                  'tourist_count': int.parse(countController.text),
                  'notes': notesController.text,
                });
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Arrivée enregistrée avec succès'))
                  );
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateAmountDialog(Map<String, dynamic> visit) {
    final amountController = TextEditingController(text: visit['spent_amount']?.toString() ?? '0');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre à jour le montant dépensé'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Montant total encaissé (DH)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
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
                  _loadData();
                }
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final agency = context.watch<AgencyProvider>().agency;

    return Scaffold(
      appBar: AppBar(
        title: Text(agency?.name ?? 'Dashboard Agence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AgencyProvider>().logout();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Commission', '${agency?.totalCommission.toStringAsFixed(2)} DH', Colors.green),
                    _buildStatCol('Total Ventes', '${agency?.totalAmount.toStringAsFixed(2)} DH', Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Historique des Visites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _visitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final visits = snapshot.data ?? [];
                if (visits.isEmpty) return const Text('Aucune visite enregistrée');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    final v = visits[index];
                    final isPaid = v['confirmed_by_manager'] == 1 || v['confirmed_by_manager'] == true;
                    
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(v['status']),
                          child: const Icon(Icons.group, color: Colors.white),
                        ),
                        title: Text('${v['tourist_count']} Touristes - ${v['cafe']['name']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dépense: ${v['spent_amount'] ?? 0} DH | Com: ${v['commission_amount'] ?? 0} DH'),
                            Text('Statut: ${v['status']} ${isPaid ? "(Payé)" : ""}', 
                              style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)
                            ),
                            Text('Date: ${v['visit_date']}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: const Icon(Icons.edit_note, color: Colors.blue),
                        onTap: isPaid ? null : () => _showUpdateAmountDialog(v),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitVisitDialog,
        label: const Text('Arrivée de Touristes'),
        icon: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
