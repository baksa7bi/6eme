import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cafe.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _locationController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  List<Cafe> _cafes = [];
  Cafe? _selectedCafe;
  String? _selectedCafeId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCafes();
  }

  Future<void> _loadCafes() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final cafes = await ApiService.getCafes();
      setState(() {
        _cafes = cafes;
        if (auth.user?.isManager == true && auth.user?.cafeId != null) {
          _selectedCafe = _cafes.firstWhere(
            (c) => c.id == auth.user!.cafeId.toString(),
            orElse: () => _cafes.first,
          );
          _selectedCafeId = _selectedCafe?.id;
        } else if (_cafes.isNotEmpty) {
          _selectedCafe = _cafes.first;
          _selectedCafeId = _selectedCafe?.id;
        }

        if (_selectedCafe != null) {
          _locationController.text = _selectedCafe!.address;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCafeId == null) return;

    setState(() => _isSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      date: eventDateTime,
      imageUrl: '', // Backend provides URL
      videoUrl: _videoUrlController.text.isNotEmpty ? _videoUrlController.text : null,
      location: _locationController.text,
      cafe: _selectedCafe,
    );

    final result = await ApiService.addEvent(newEvent, imageFile: _imageFile, userId: auth.user!.id, cafeId: _selectedCafeId);

    setState(() => _isSubmitting = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Évènement ajouté avec succès !')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Erreur lors de l'ajout."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Évènement'),
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
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Titre de l'évènement"),
                      validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        bool isManagerOnly = auth.user?.isManager == true && !auth.user!.isAdmin;
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Café / Lieu',
                            helperText: isManagerOnly ? 'Assigné à votre café' : null,
                          ),
                          initialValue: _selectedCafeId,
                          items: [
                            if (auth.user?.isAdmin == true)
                              const DropdownMenuItem<String>(
                                value: 'all',
                                child: Text('Tous les cafés (Admin)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                            ..._cafes.map((cafe) {
                              return DropdownMenuItem<String>(
                                value: cafe.id,
                                child: Text(cafe.name),
                              );
                            }),
                          ],
                          onChanged: isManagerOnly ? null : (value) {
                            setState(() {
                              _selectedCafeId = value;
                              if (value == 'all') {
                                _selectedCafe = null;
                                _locationController.text = 'Tous les cafés';
                              } else {
                                _selectedCafe = _cafes.firstWhere((c) => c.id == value);
                                if (_selectedCafe != null) {
                                  _locationController.text = _selectedCafe!.address;
                                }
                              }
                            });
                          },
                          validator: (value) => value == null ? 'Sélectionnez un café' : null,
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Adresse / Emplacement (Auto)'),
                      validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Date time row
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Date'),
                            subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) setState(() => _selectedDate = date);
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Heure'),
                            subtitle: Text(_selectedTime.format(context)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (time != null) setState(() => _selectedTime = time);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Image Picker Section
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 70, // This compresses the image to ~1-2MB typically
                        );
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(labelText: 'URL de la vidéo (Optionnel)'),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Ajouter l'évènement", style: TextStyle(fontSize: 16)),
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
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
