import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/agency.dart';

class AgenciesPage extends StatefulWidget {
  const AgenciesPage({super.key});

  @override
  State<AgenciesPage> createState() => _AgenciesPageState();
}

class _AgenciesPageState extends State<AgenciesPage> {
  late Future<List<Agency>> _agenciesFuture;

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  void _loadAgencies() {
    setState(() {
      _agenciesFuture = ApiService.getAgencies();
    });
  }

  void _showAddAgencyDialog() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une Agence'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom de l\'agence')),
              TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Personne de contact')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Téléphone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final success = await ApiService.addAgency({
                  'name': nameController.text,
                  'contact_person': contactController.text,
                  'phone': phoneController.text,
                  'email': emailController.text,
                  'password': passwordController.text,
                });
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadAgencies();
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Agences'),
        actions: [
          IconButton(onPressed: _loadAgencies, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Agency>>(
        future: _agenciesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final agencies = snapshot.data ?? [];
          if (agencies.isEmpty) {
            return const Center(child: Text('Aucune agence trouvée'));
          }
          return ListView.builder(
            itemCount: agencies.length,
            itemBuilder: (context, index) {
              final agency = agencies[index];
              return ListTile(
                title: Text(agency.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${agency.contactPerson ?? ''} - ${agency.phone ?? ''}'),
                    const SizedBox(height: 4),
                    Text(
                      'Commandes: ${agency.ordersCount} | Commission: ${agency.totalCommission.toStringAsFixed(2)} DH',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Supprimer l\'agence ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final success = await ApiService.deleteAgency(agency.id);
                      if (success && mounted) _loadAgencies();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAgencyDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
