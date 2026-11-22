import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/dates.dart';
import '../../../domain/timetable.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_badge.dart';
import '../../../ui/section_label.dart';
import '../../college_portal/timetable_store.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Week view of the timetable inferred from attendance sessions.
class TimetableSection extends ConsumerWidget {
  const TimetableSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final slots = ref.watch(timetableProvider);
    if (slots.isEmpty) return const SizedBox.shrink();
    final today = weekdayOf(todayLocal(ref.watch(clockProvider)()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Timetable'),
        const SizedBox(height: 4),
        Text(
          'Built from your attendance records.',
          style: TextStyle(color: c.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (var d = 1; d <= 7; d++)
          if (slots.any((s) => s.weekday == d))
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Tokens.radiusCard),
                border: Border.all(color: d == today ? c.accent : c.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      _days[d - 1],
                      style: TextStyle(
                        fontFamily: mono,
                        fontSize: 12,
                        color: d == today ? c.accent : c.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in slots.where((s) => s.weekday == d))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${s.start}–${s.end}',
                                  style: TextStyle(
                                    fontFamily: mono,
                                    fontSize: 12,
                                    color: c.muted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.courseName == null
                                        ? s.courseCode
                                        : '${s.courseCode} · ${s.courseName}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (s.isLab) const AppBadge('lab'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// "Now · CS311 09:00–10:00" / "Next · …" for Today.
class NowNextClass extends ConsumerWidget {
  const NowNextClass({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final slots = ref.watch(timetableProvider);
    if (slots.isEmpty) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final r = nowAndNext(slots, weekdayOf(todayLocal(now)), formatTime(now));
    if (r.now == null && r.next == null) return const SizedBox.shrink();
    Widget line(String label, ClassSlot s, Color color) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(fontFamily: mono, fontSize: 11, color: color),
            ),
            TextSpan(text: s.courseName ?? s.courseCode),
            TextSpan(
              text: '  ${s.start}–${s.end}',
              style: TextStyle(fontFamily: mono, fontSize: 11, color: c.muted),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.now case final s?) line('NOW', s, c.accent),
        if (r.next case final s?) line('NEXT', s, c.muted),
      ],
    );
  }
}
