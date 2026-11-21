import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_checkbox.dart';

/// A Today row that completes in place: flips immediately, rolls back on failure.
class CheckRow extends StatefulWidget {
  const CheckRow({
    super.key,
    required this.title,
    required this.done,
    required this.onToggle,
    this.trailing,
    this.subtitle,
    this.highlight = false,
  });

  final String title;
  final bool done;

  /// Persists the change; returns an error message, or null on success.
  final Future<String?> Function(bool next) onToggle;
  final String? trailing;
  final String? subtitle;
  final bool highlight;

  @override
  State<CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<CheckRow> {
  late bool _done = widget.done;

  @override
  void didUpdateWidget(CheckRow old) {
    super.didUpdateWidget(old);
    if (old.done != widget.done) _done = widget.done;
  }

  Future<void> _toggle(bool next) async {
    setState(() => _done = next);
    final error = await widget.onToggle(next);
    if (error != null && mounted) {
      setState(() => _done = !next);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: AppCheckbox(
            value: _done,
            label: widget.subtitle == null
                ? widget.title
                : '${widget.title} · ${widget.subtitle}',
            labelStyle: TextStyle(
              color: _done ? c.muted : (widget.highlight ? c.accent : c.text),
              decoration: _done ? TextDecoration.lineThrough : null,
            ),
            onChanged: _toggle,
          ),
        ),
        if (widget.trailing != null)
          Text(
            widget.trailing!,
            style: TextStyle(
              fontFamily: mono,
              fontSize: 11,
              color: widget.highlight && !_done ? c.accent : c.muted,
            ),
          ),
      ],
    );
  }
}
