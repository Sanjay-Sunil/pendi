import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_progress_bar.dart';

typedef ProgressPart = ({String label, int done, int total});

/// "4 of 9 done today" with a bar and a per-area breakdown.
class DayProgress extends StatelessWidget {
  const DayProgress({super.key, required this.parts});

  final List<ProgressPart> parts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final live = parts.where((p) => p.total > 0).toList();
    final done = live.fold(0, (n, p) => n + p.done);
    final total = live.fold(0, (n, p) => n + p.total);
    final allDone = total > 0 && done == total;
    return Semantics(
      label: '$done of $total done today',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$done',
                style: TextStyle(
                  fontFamily: mono,
                  fontSize: 32,
                  height: 1,
                  color: allDone ? c.accent : c.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                ' / $total',
                style: TextStyle(
                  fontFamily: mono,
                  fontSize: 18,
                  color: c.muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  total == 0
                      ? 'A clear day.'
                      : allDone
                      ? 'All done today. Nice.'
                      : 'done today',
                  style: TextStyle(color: c.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(
            value: done,
            max: total == 0 ? 1 : total,
            label: 'Today progress',
          ),
          if (live.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [for (final p in live) '${p.label} ${p.done}/${p.total}']
                  .join('  ·  '),
              style: TextStyle(fontFamily: mono, fontSize: 11, color: c.muted),
            ),
          ],
        ],
      ),
    );
  }
}
