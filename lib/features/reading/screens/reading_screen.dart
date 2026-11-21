import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_sheet.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/page_scaffold.dart';
import '../providers.dart';
import '../widgets/add_source_sheet.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  static Future<void> openAdd(BuildContext context, {String? url}) =>
      showAppSheet<void>(
        context,
        title: 'Add reading',
        child: AddSourceForm(initialUrl: url),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(readingOverviewProvider);
    final pagesToday =
        overview.value?.fold<int>(0, (n, o) => n + o.plan.items.length) ?? 0;
    return PageScaffold(
      title: 'Reading',
      label:
          'Planner · $pagesToday ${pagesToday == 1 ? 'page' : 'pages'} today',
      onRefresh: () => ref.refresh(readingOverviewProvider.future),
      actions: [
        AppButton(
          label: 'Add',
          icon: LucideIcons.plus,
          small: true,
          onPressed: () => openAdd(context),
        ),
      ],
      children: [
        ...overview.when(
          loading: () => [const LinearProgressIndicator()],
          error: (e, _) => [Text('Could not load reading: $e')],
          data: (list) => list.isEmpty
              ? [
                  EmptyState(
                    message:
                        'No reading yet. Add a course or blog link to start.',
                    actionLabel: 'Add a link',
                    onAction: () => openAdd(context),
                  ),
                ]
              : [
                  for (final o in list) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.source.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${o.plan.quota} ${o.plan.quota == 1 ? 'page' : 'pages'} today',
                            style: TextStyle(
                              fontFamily: mono,
                              color: context.colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
        ),
      ],
    );
  }
}
