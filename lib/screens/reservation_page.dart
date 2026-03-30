import 'package:flutter/material.dart';
import '../models/cafe.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import 'login_page.dart';
import '../providers/reservation_provider.dart';
import '../models/reservation.dart';

// ── Custom time-picker dialog ─────────────────────────────────────────────────
/// Shows two scroll wheels (hour 15-23 / minute 00-59) constrained to the
/// reservation window [15:30 – 23:30].  Returns the chosen [TimeOfDay] or
/// null if the user cancelled.
Future<TimeOfDay?> showReservationTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (ctx) => _ReservationTimePickerDialog(initial: initialTime),
  );
}

class _ReservationTimePickerDialog extends StatefulWidget {
  final TimeOfDay initial;
  const _ReservationTimePickerDialog({required this.initial});

  @override
  State<_ReservationTimePickerDialog> createState() =>
      _ReservationTimePickerDialogState();
}

class _ReservationTimePickerDialogState
    extends State<_ReservationTimePickerDialog> {
  // Valid hour range
  static const int _minHour = 15;
  static const int _maxHour = 23;

  late int _hour;
  late int _minute;

  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  // Minutes available for the currently selected hour
  List<int> get _validMinutes {
    final List<int> mins = [];
    final int from = (_hour == _minHour) ? 30 : 0;
    final int to   = (_hour == _maxHour) ? 30 : 59;
    for (int m = from; m <= to; m++) {
      mins.add(m);
    }
    return mins;
  }

  @override
  void initState() {
    super.initState();

    // Clamp initial values to the valid window
    _hour   = widget.initial.hour.clamp(_minHour, _maxHour);
    _minute = widget.initial.minute;

    // Re-clamp minute after hour is fixed
    final mins = _validMinutesFor(_hour);
    if (!mins.contains(_minute)) {
      _minute = mins.first;
    }

    _hourCtrl   = FixedExtentScrollController(initialItem: _hour - _minHour);
    _minuteCtrl = FixedExtentScrollController(
        initialItem: mins.indexOf(_minute));
  }

  List<int> _validMinutesFor(int h) {
    final List<int> list = [];
    final int from = (h == _minHour) ? 30 : 0;
    final int to   = (h == _maxHour) ? 30 : 59;
    for (int m = from; m <= to; m++) list.add(m);
    return list;
  }

  void _onHourChanged(int index) {
    final newHour = _minHour + index;
    final newMins = _validMinutesFor(newHour);

    setState(() {
      _hour = newHour;
      // Keep minute if still valid, else jump to nearest valid
      if (!newMins.contains(_minute)) {
        _minute = newMins.first;
      }
    });

    // Animate the minute wheel to the (possibly adjusted) valid position
    final minuteIndex = newMins.indexOf(_minute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_minuteCtrl.hasClients) {
        _minuteCtrl.animateToItem(
          minuteIndex,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMinuteChanged(int index) {
    setState(() => _minute = _validMinutes[index]);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required List<String> items,
    required void Function(int) onChanged,
  }) {
    return SizedBox(
      width: 72,
      height: 160,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        perspective: 0.003,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (_, i) => Center(
            child: Text(
              items[i],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final hours      = List.generate(_maxHour - _minHour + 1, (i) => (_minHour + i).toString().padLeft(2,'0'));
    final minuteList = _validMinutes.map((m) => m.toString().padLeft(2,'0')).toList();

    return AlertDialog(
      title:   const Text('Heure de réservation', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Horaire disponible : 15:30 – 23:30',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _wheel(
                controller: _hourCtrl,
                items: hours,
                onChanged: _onHourChanged,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              // Rebuild minute wheel whenever hour changes
              _wheel(
                controller: _minuteCtrl,
                items: minuteList,
                onChanged: _onMinuteChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Live preview
          Text(
            '${_hour.toString().padLeft(2,'0')}:${_minute.toString().padLeft(2,'0')}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute)),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────

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
                // `time` is always within the valid window or null (cancelled)
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

                  // Final safety-net (custom picker already guarantees this)
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

                  final formattedTime =
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
                  final day    = _selectedDate.day;
                  final month  = _selectedDate.month;
                  final year   = _selectedDate.year;
                  final people = _numberOfPeople;

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

                  if (mounted) Navigator.of(context).pop();
                },
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
}
