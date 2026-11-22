import 'package:flutter/material.dart';

import '../../../domain/dates.dart';
import '../../../theme/tokens.dart';
import '../../../ui/section_label.dart';
import '../today_cache.dart';

class OfflineToday extends StatelessWidget {
  const OfflineToday({super.key, required this.snapshot});

  final TodaySnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(Tokens.radiusControl),
          ),
          child: Semantics(
            liveRegion: true,
            child: Text(
              s == null
                  ? "You're offline and nothing is saved yet. Pull to retry."
                  : "You're offline. Showing Today from ${formatTime(s.savedAt)}, "
                        '${formatDayLabel(toLocalDay(s.savedAt))}. Pull to retry.',
              style: TextStyle(color: c.text),
            ),
          ),
        ),
        if (s != null)
          for (final (label, lines) in s.sections)
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionLabel(label),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(l),
                ),
            ],
      ],
    );
  }
}

/// The cached Today shown during a normal load, with a quiet "Updating" note.
class CachedToday extends StatelessWidget {
  const CachedToday({super.key, required this.snapshot});

  final TodaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 4),
        Text('Updating…', style: TextStyle(color: c.muted, fontSize: 12)),
        for (final (label, lines) in snapshot.sections)
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionLabel(label),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(l),
              ),
          ],
      ],
    );
  }
}
