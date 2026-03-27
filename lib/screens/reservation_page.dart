import 'package:flutter/material.dart';
import '../models/cafe.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import '../providers/reservation_provider.dart';
import '../models/reservation.dart';

class ReservationPage extends StatefulWidget {
  final Cafe cafe;
  const ReservationPage({super.key, required this.cafe});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);
  int _numberOfPeople = 2;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Réserver - ${widget.cafe.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Détails de la réservation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Date Picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const Divider(),
            
            // Time Picker
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) setState(() => _selectedTime = time);
              },
            ),
            const Divider(),
            
            // People Count
            Row(
              children: [
                const Icon(Icons.people, color: Colors.grey),
                const SizedBox(width: 16),
                const Text('Nombre de personnes :', style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (_numberOfPeople > 1) setState(() => _numberOfPeople--);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_numberOfPeople', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    setState(() => _numberOfPeople++);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Divider(),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (!auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                    return;
                  }

                  if (!auth.user!.isEmailVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez vérifier votre adresse e-mail pour effectuer une réservation.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
                  
                  // Create reservation object
                  final reservation = Reservation(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    cafeId: widget.cafe.id,
                    cafeName: widget.cafe.name,
                    userId: auth.user?.id ?? 'guest',
                    dateTime: DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    ),
                    numberOfPeople: _numberOfPeople,
                    type: 'table',
                    status: 'pending',
                  );

                  final success = await reservationProvider.createReservation(reservation);
                  
                  if (!success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erreur lors de la réservation. Veuillez réessayer.')),
                      );
                    }
                    return;
                  }

                  // Capture the time format before async gap
                  final formattedTime = _selectedTime.format(context);
                  final day = _selectedDate.day;
                  final month = _selectedDate.month;
                  final year = _selectedDate.year;
                  final people = _numberOfPeople;

                  // Show success dialog — use a separate dialogContext so we
                  // never accidentally pop the wrong route
                  await showDialog(
                    context: context,
                    useRootNavigator: false,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Réservation Confirmée ✅'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Votre table pour $people personnes est réservée.'),
                          const SizedBox(height: 8),
                          Text('Date: $day/$month/$year'),
                          Text('Heure: $formattedTime'),
                          const SizedBox(height: 16),
                          const Text('Nous vous attendons avec impatience !',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Génial !'),
                        ),
                      ],
                    ),
                  );

                  // After dialog closed, go back to the café detail page
                  if (mounted) Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmer la réservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
