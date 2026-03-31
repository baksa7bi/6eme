import 'package:flutter/material.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(TimeOfDay(hour: _hour, minute: _minute)),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
