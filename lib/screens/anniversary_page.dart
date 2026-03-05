import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../models/reservation.dart';

class AnniversaryPage extends StatefulWidget {
  const AnniversaryPage({super.key});

  @override
  State<AnniversaryPage> createState() => _AnniversaryPageState();
}

class _AnniversaryPageState extends State<AnniversaryPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCafe;
  final TextEditingController _guestsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _cafes = [
    'Café Central',
    'Le Petit Oasis',
    'Sushi Sky',
    'The Green Garden',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver un Anniversaire'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Célébrez votre anniversaire avec nous !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Remplissez le formulaire ci-dessous pour réserver un espace dédié.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              // Cafe Selection
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Choisir un établissement',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: _selectedCafe,
                items: _cafes.map((cafe) => DropdownMenuItem(value: cafe, child: Text(cafe))).toList(),
                onChanged: (val) => setState(() => _selectedCafe = val),
                validator: (val) => val == null ? 'Veuillez choisir un café' : null,
              ),
              const SizedBox(height: 20),

              // Date Selection
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de l\'événement',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _selectedDate == null 
                      ? 'Sélectionner une date' 
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Selection
              InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Heure de début',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _selectedTime == null 
                      ? 'Sélectionner l\'heure' 
                      : _selectedTime!.format(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Number of guests
              TextFormField(
                controller: _guestsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nombre d\'invités',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Veuillez entrer un nombre' : null,
              ),
              const SizedBox(height: 20),

              // Special Requests
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes ou demandes spéciales (Gâteau, Décoration...)',
                  hintText: 'Précisez si vous souhaitez un gâteau particulier...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
                      
                      // Save reservation
                      final reservation = Reservation(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        cafeId: _selectedCafe ?? 'unknown',
                        cafeName: _selectedCafe ?? 'unknown',
                        userId: auth.user?.id ?? 'guest',
                        dateTime: DateTime(
                          _selectedDate!.year,
                          _selectedDate!.month,
                          _selectedDate!.day,
                          _selectedTime!.hour,
                          _selectedTime!.minute,
                        ),
                        numberOfPeople: int.tryParse(_guestsController.text) ?? 1,
                        specialRequests: _notesController.text,
                        status: 'pending', // Anniversary requests start as pending
                      );

                      reservationProvider.addReservation(reservation);
                      
                      // Submit logic
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Demande envoyée'),
                          content: const Text('Votre demande de réservation pour anniversaire a été reçue. Nous vous contacterons pour confirmer les détails.'),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(context); // Go back
                              }, 
                              child: const Text('OK')
                            ),
                          ],
                        ),
                      );
                    } else if (_selectedDate == null || _selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez sélectionner la date et l\'heure')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Envoyer la demande', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
