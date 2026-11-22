import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/dates.dart';
import '../domain/heatmap.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// GitHub / Codeforces-style activity grid, in amber. Fits as many weeks as
/// the width allows (up to [maxWeeks]); tap a square for that day's count.
class StreakHeatmap extends StatelessWidget {
  const StreakHeatmap({
    super.key,
    required this.counts,
    required this.today,
    this.unit = 'done',
    this.maxWeeks = 26,
    this.showStats = true,
  });

  final Map<LocalDay, int> counts;
  final LocalDay today;

  /// Word used in tooltips and stats, e.g. "solved".
  final String unit;
  final int maxWeeks;
  final bool showStats;

  static const cell = 12.0;
  static const gap = 3.0;
  static const _labelWidth = 26.0;

  Color _color(PendiColors c, int level) => switch (level) {
    0 => c.surface2,
    1 => Color.alphaBlend(c.accent.withValues(alpha: 0.30), c.surface2),
    2 => Color.alphaBlend(c.accent.withValues(alpha: 0.55), c.surface2),
    3 => Color.alphaBlend(c.accent.withValues(alpha: 0.80), c.surface2),
    _ => c.accent,
  };

  String _dayLabel(LocalDay d) {
    final [y, m, dd] = d.split('-').map(int.parse).toList();
    return DateFormat('EEE, d MMM').format(DateTime.utc(y, m, dd));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stats = streakStats(counts, today);
    final labelStyle = TextStyle(
      fontFamily: mono,
      fontSize: 10,
      color: c.muted,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final fit = ((box.maxWidth - _labelWidth + gap) / (cell + gap)).floor();
        final weeks = heatmapWeeks(
          counts,
          today,
          weeks: fit.clamp(4, maxWeeks),
        );
        final busiest = weeks
            .expand((w) => w)
            .fold<int>(0, (m, x) => max(m, x.count));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label:
                  '${stats.activeDays} active days, current streak ${stats.current}, '
                  'longest ${stats.longest}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month labels above the first week of each month.
                  Padding(
                    padding: const EdgeInsets.only(left: _labelWidth),
                    child: SizedBox(
                      height: 14,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (var w = 0; w < weeks.length; w++)
                            if (w == 0 ||
                                weeks[w].first.day.substring(5, 7) !=
                                    weeks[w - 1].first.day.substring(5, 7))
                              Positioned(
                                left: w * (cell + gap),
                                child: Text(
                                  DateFormat(
                                    'MMM',
                                  ).format(DateTime.parse(weeks[w].first.day)),
                                  style: labelStyle,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _labelWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final d in [
                              'Mon',
                              '',
                              'Wed',
                              '',
                              'Fri',
                              '',
                              '',
                            ])
                              SizedBox(
                                height: cell + gap,
                                child: Text(d, style: labelStyle),
                              ),
                          ],
                        ),
                      ),
                      for (final week in weeks)
                        Padding(
                          padding: const EdgeInsets.only(right: gap),
                          child: Column(
                            children: [
                              for (final day in week)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: gap),
                                  child: day.future
                                      ? const SizedBox(
                                          width: cell,
                                          height: cell,
                                        )
                                      : Tooltip(
                                          message:
                                              '${day.count} $unit on ${_dayLabel(day.day)}',
                                          triggerMode: TooltipTriggerMode.tap,
                                          child: Container(
                                            width: cell,
                                            height: cell,
                                            decoration: BoxDecoration(
                                              color: _color(
                                                c,
                                                heatLevel(day.count, busiest),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2.5),
                                              border: day.day == today
                                                  ? Border.all(
                                                      color: c.text,
                                                      width: 1,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (showStats)
                  Expanded(
                    child: Text(
                      '${stats.total} $unit · ${stats.current}d streak · best ${stats.longest}d',
                      style: labelStyle.copyWith(fontSize: 11),
                    ),
                  )
                else
                  const Spacer(),
                Text('Less ', style: labelStyle),
                for (var l = 0; l <= 4; l++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: _color(c, l),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Text(' More', style: labelStyle),
              ],
            ),
          ],
        );
      },
    );
  }
}
