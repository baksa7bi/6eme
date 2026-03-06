import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cafe.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  List<Cafe> _cafes = [];
  String? _selectedCafeId;
  
  List<String> _categories = [];
  String? _selectedCategory;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getCafes(),
        ApiService.getCategories(),
      ]);

      setState(() {
        _cafes = results[0] as List<Cafe>;
        _categories = results[1] as List<String>;

        if (_cafes.isNotEmpty) {
          _selectedCafeId = _cafes.first.id.toString();
        }
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données : $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCafeId == null || _selectedCategory == null) return;

    setState(() => _isSubmitting = true);

    final newItem = MenuItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      description: _descriptionController.text,
      category: _selectedCategory!,
      cafeId: _selectedCafeId!,
      imageUrl: '', // Backend handles the final URL
    );

    final success = await ApiService.addMenuItem(newItem, imageFile: _imageFile);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit ajouté avec succès !')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'ajout. Veuillez réessayer.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Produit'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nom du produit'),
                      validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Prix (DH)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      value: _selectedCategory,
                      items: _categories.map((catName) {
                        return DropdownMenuItem<String>(
                          value: catName,
                          child: Text(catName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) => value == null ? 'Veuillez sélectionner une catégorie' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Café'),
                      value: _selectedCafeId,
                      items: _cafes.map((cafe) {
                        return DropdownMenuItem<String>(
                          value: cafe.id.toString(),
                          child: Text(cafe.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCafeId = value;
                        });
                      },
                      validator: (value) => value == null ? 'Veuillez sélectionner un café' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Image Picker Section
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            _imageFile = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _imageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text("Toucher pour sélectionner une image", style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Ajouter le produit', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
