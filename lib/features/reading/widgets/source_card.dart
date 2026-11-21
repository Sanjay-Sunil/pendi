import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_progress_bar.dart';
import '../../../ui/section_label.dart';
import '../providers.dart';
import 'reading_item_row.dart';

class SourceCard extends ConsumerWidget {
  const SourceCard({super.key, required this.overview});

  final SourceOverview overview;

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = await ref.read(readingRepoProvider.future);
    final res = await repo.archive(overview.source.id);
    ref.invalidate(readingOverviewProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          res.isOk ? 'Archived ${overview.source.title}' : res.errorOrNull!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final o = overview;
    final days = o.plan.daysLeft;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.source.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${o.done}/${o.total} read · $days ${days == 1 ? 'day' : 'days'} left',
                      style: TextStyle(
                        fontFamily: mono,
                        fontSize: 12,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Archive',
                small: true,
                variant: ButtonVariant.secondary,
                onPressed: () => _archive(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppProgressBar(
            value: o.done,
            max: o.total,
            label: '${o.source.title} progress',
          ),
          const SizedBox(height: 12),
          if (o.plan.items.isEmpty)
            Text(
              'All caught up. Nothing due today.',
              style: TextStyle(color: c.muted),
            )
          else ...[
            SectionLabel(
              'Today · ${o.plan.quota} ${o.plan.quota == 1 ? 'page' : 'pages'}',
            ),
            for (final p in o.plan.items)
              ReadingItemRow(
                key: ValueKey(p.item.id),
                item: p.item,
                carriedOver: p.carriedOver,
              ),
          ],
        ],
      ),
    );
  }
}
