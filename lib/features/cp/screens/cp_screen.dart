import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/providers.dart';
import '../../../domain/dates.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_input.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/page_scaffold.dart';
import '../../../ui/section_label.dart';
import '../../../ui/streak_flame.dart';
import '../../../ui/streak_heatmap.dart';
import '../providers.dart';
import '../widgets/lists_section.dart';
import '../widgets/problem_card.dart';

class CpScreen extends ConsumerStatefulWidget {
  const CpScreen({super.key});

  @override
  ConsumerState<CpScreen> createState() => _CpScreenState();
}

class _CpScreenState extends ConsumerState<CpScreen> {
  final _handle = TextEditingController();

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = await ref.read(cpSyncProvider.notifier).sync();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveHandle() async {
    await (await ref.read(profileRepoProvider.future))
        .update(cfHandle: _handle.text);
    ref.invalidate(cpTodayProvider);
    await _sync();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(cpTodayProvider);
    final syncing = ref.watch(cpSyncProvider);
    final data = today.value;
    return PageScaffold(
      title: 'CP',
      label: 'Practice',
      onRefresh: () async {
        ref.invalidate(cpListsProvider);
        ref.invalidate(cpTodayProvider);
        await ref.read(cpTodayProvider.future);
      },
      actions: [if (data != null) StreakFlame(data.streak)],
      children: [
        if (today.isLoading && data == null) const LinearProgressIndicator(),
        if (today.hasError) Text('Could not load CP: ${today.error}'),
        if (data != null) ...[
          const SectionLabel("Today's two"),
          const SizedBox(height: 8),
          if (!data.hasList)
            const EmptyState(
              message: 'Import a list below to get daily problems.',
            )
          else if (data.problems.isEmpty)
            const EmptyState(
              message: 'List finished. Activate or import another one.',
            )
          else
            for (final p in data.problems) ...[
              ProblemCard(key: ValueKey(p.id), problem: p),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 8),
          if (data.handle == null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Codeforces handle',
                    controller: _handle,
                    hint: 'tourist',
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(label: 'Save', onPressed: _saveHandle),
              ],
            )
          else
            AppButton(
              label: syncing
                  ? 'Syncing…'
                  : 'Sync from Codeforces (${data.handle})',
              icon: LucideIcons.refreshCw,
              variant: ButtonVariant.secondary,
              onPressed: syncing ? null : _sync,
            ),
          const SizedBox(height: 24),
          const SectionLabel('Activity'),
          const SizedBox(height: 8),
          StreakHeatmap(
            counts: data.solvesByDay,
            today: todayLocal(ref.watch(clockProvider)()),
            unit: 'solved',
          ),
          if (data.review.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionLabel('Review queue · ${data.review.length}'),
            const SizedBox(height: 4),
            for (final p in data.review)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  p.label,
                  style: TextStyle(color: context.colors.muted),
                ),
              ),
          ],
        ],
        const SizedBox(height: 24),
        ListsSection(onChanged: () => ref.invalidate(cpTodayProvider)),
      ],
    );
  }
}
