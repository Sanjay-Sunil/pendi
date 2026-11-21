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
      return Text('No events today.', style: TextStyle(color: c.muted));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final e in events)
            Container(
              width: 160,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(Tokens.radiusControl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.allDay ? 'All day' : formatTime(e.startsAt),
                    style: TextStyle(
                      fontFamily: mono,
                      fontSize: 11,
                      color: c.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
