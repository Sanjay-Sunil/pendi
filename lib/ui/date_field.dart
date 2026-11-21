import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_button.dart';

/// Button that opens date + time pickers; shows the chosen value.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Due',
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String label;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        value ?? DateTime(now.year, 1, 1, 23, 59),
      ),
    );
    final t = time ?? const TimeOfDay(hour: 23, minute: 59);
    onChanged(DateTime(date.year, date.month, date.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      small: true,
      variant: ButtonVariant.secondary,
      label: value == null
          ? '$label: none'
          : '$label: ${DateFormat('d MMM, HH:mm').format(value!)}',
      onPressed: () => _pick(context),
    );
  }
}
