import 'package:flutter/material.dart';
import '../widgets/time_picker.dart';
import '../models/cafe.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
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
  TimeOfDay _selectedTime = const TimeOfDay(hour: 15, minute: 30);
  int _numberOfPeople = 2;

  bool _isTimeAllowed(TimeOfDay t) {
    final mins  = t.hour * 60 + t.minute;
    const open  = 15 * 60 + 30; // 930
    const close = 23 * 60 + 30; // 1410
    return mins >= open && mins <= close;
  }

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

            // Time Picker — custom restricted picker
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              ),
              subtitle: const Text('15:30 – 23:30', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final time = await showReservationTimePicker(
                  context,
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
                onPressed: () => _handleSubmit(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmer la réservation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.user?.role != 'client') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En tant que personnel, vous ne pouvez pas réserver.')),
      );
      return;
    }
    if (!auth.isAuthenticated) {
      Provider.of<NavigationProvider>(context, listen: false)
          .pushOnCurrentTab(context, const LoginPage());
      return;
    }

    if (!_isTimeAllowed(_selectedTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Les réservations ne sont acceptées qu\'entre 15h30 et 23h30.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (auth.user!.role == 'client' && !auth.user!.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vérifier votre adresse e-mail pour effectuer une réservation.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reservationProvider =
        Provider.of<ReservationProvider>(context, listen: false);

    final reservation = Reservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cafeId: widget.cafe.id,
      cafeName: widget.cafe.name,
      userId: auth.user!.id,
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
          const SnackBar(content: Text('Erreur lors de la réservation.')),
        );
      }
      return;
    }

    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    
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
            Text('Votre table pour $_numberOfPeople personnes est réservée.'),
            const SizedBox(height: 8),
            Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
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

    if (mounted) Navigator.of(context).pop();
  }
}
