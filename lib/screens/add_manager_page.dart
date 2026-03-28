import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/cafe.dart';
class AddManagerPage extends StatefulWidget {
  const AddManagerPage({super.key});

  @override
  State<AddManagerPage> createState() => _AddManagerPageState();
}

class _AddManagerPageState extends State<AddManagerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _selectedCafeId;
  List<Cafe> _cafes = [];

  @override
  void initState() {
    super.initState();
    _loadCafes();
  }

  Future<void> _loadCafes() async {
    try {
      final cafes = await ApiService.getCafes();
      if (mounted) {
        setState(() {
          _cafes = cafes;
        });
      }
    } catch (e) {
      debugPrint('Error loading cafes: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ApiService.addManager(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      _phoneController.text,
      _selectedCafeId!,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manager ajouté avec succès !')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l\'ajout du manager. Vérifiez vos informations.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un Manager')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom complet *'),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (value) => value == null || value.isEmpty || !value.contains('@') ? 'Email invalide' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone *'),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe *'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Champ requis';
                  if (value.length < 8) return 'Minimum 8 caractères';
                  if (!value.contains(RegExp(r'[a-zA-Z]')) || !value.contains(RegExp(r'[0-9]'))) {
                    return 'Doit contenir une lettre et un chiffre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Sélectionner le Café *'),
                initialValue: _selectedCafeId,
                items: _cafes.map((cafe) {
                  return DropdownMenuItem<String>(
                    value: cafe.id,
                    child: Text(cafe.name),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCafeId = value),
                validator: (value) => value == null ? 'Veuillez sélectionner un café' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Ajouter le Manager'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
