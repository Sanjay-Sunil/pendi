import 'package:flutter/material.dart';

import '../../../data/repos/gcal_repo.dart';
import '../../../domain/dates.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';

class CalendarStrip extends StatelessWidget {
  const CalendarStrip({super.key, required this.events});

  final List<CachedEvent> events;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text('No events today.', style: TextStyle(color: c.muted)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Equal-height cards: every card stretches to the tallest one.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in events)
              Container(
                width: 168,
                margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  border: Border(left: BorderSide(color: c.accent, width: 2)),
                  borderRadius: BorderRadius.circular(Tokens.radiusControl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.allDay
                          ? 'All day'
                          : e.endsAt == null
                          ? formatTime(e.startsAt)
                          : '${formatTime(e.startsAt)} – ${formatTime(e.endsAt!)}',
                      style: TextStyle(
                        fontFamily: mono,
                        fontSize: 11,
                        color: c.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.35),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
