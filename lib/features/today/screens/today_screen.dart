import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/research.dart';
import '../../../data/providers.dart';
import '../../../domain/cp.dart';
import '../../../domain/dates.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_sheet.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/page_scaffold.dart';
import '../../../ui/section_label.dart';
import '../../../ui/streak_flame.dart';
import '../../college/providers.dart';
import '../../cp/providers.dart';
import '../../habits/habits_section.dart';
import '../../hackathons/providers.dart';
import '../../notes/evening_review.dart';
import '../../notes/providers.dart';
import '../../reading/widgets/reading_item_row.dart';
import '../../research/providers.dart';
import '../providers.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/check_row.dart';

String greeting(DateTime now) {
  final hour = int.parse(formatTime(now).split(':').first);
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final today = ref.watch(todayProvider);
    final d = today.value;
    Widget gap() => const SizedBox(height: 28);

    return PageScaffold(
      title: greeting(now),
      label: formatDayLabel(todayLocal(now)),
      maxWidth: Tokens.maxToday,
      actions: [
        AppButton(
          label: 'Review',
          small: true,
          variant: ButtonVariant.ghost,
          onPressed: () => showAppSheet<void>(
            context,
            title: 'Evening review',
            child: const EveningReview(),
          ),
        ),
      ],
      onRefresh: () async {
        invalidateToday(ref);
        await ref.read(todayProvider.future);
      },
      children: [
        if (d == null && today.isLoading) const LinearProgressIndicator(),
        if (today.hasError && d == null)
          Text('Could not load today: ${today.error}'),
        if (d != null) ...[
          if ((ref.watch(todayTop3Provider).value ?? const []).isNotEmpty) ...[
            const SectionLabel('Top 3'),
            for (final (i, t) in ref.watch(todayTop3Provider).value!.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${i + 1}. $t'),
              ),
            gap(),
          ],
          const SectionLabel('Calendar'),
          const SizedBox(height: 8),
          CalendarStrip(events: d.events),
          gap(),
          SectionLabel(
            'Reading · ${d.reading.fold<int>(0, (n, o) => n + o.plan.items.length)} pages',
          ),
          if (d.reading.every((o) => o.plan.items.isEmpty))
            const EmptyState(message: 'No reading due today.'),
          for (final o in d.reading)
            for (final p in o.plan.items)
              ReadingItemRow(
                key: ValueKey(p.item.id),
                item: p.item,
                carriedOver: p.carriedOver,
              ),
          gap(),
          Row(
            children: [
              const Expanded(child: SectionLabel('CP')),
              StreakFlame(d.cp.streak),
            ],
          ),
          if (d.cp.problems.isEmpty)
            const EmptyState(message: 'No problems picked today.'),
          for (final p in d.cp.problems)
            CheckRow(
              key: ValueKey('cp-${p.id}'),
              title: p.label,
              done: p.status == CpStatus.solved,
              trailing: p.rating?.toString(),
              onToggle: (v) async {
                final repo = await ref.read(cpRepoProvider.future);
                final res = await repo.setStatus(
                  p.id,
                  v ? CpStatus.solved : CpStatus.todo,
                );
                ref.invalidate(cpTodayProvider);
                return res.errorOrNull;
              },
            ),
          gap(),
          const SectionLabel('Work'),
          if (d.work.isEmpty)
            const EmptyState(message: 'Nothing due in work today.'),
          for (final w in d.work)
            CheckRow(
              key: ValueKey('work-${w.id}'),
              title: w.title,
              subtitle: w.context,
              done: false,
              trailing: formatDue(w.dueAt, now),
              highlight: w.dueAt.isBefore(now),
              onToggle: (v) async {
                final String? err;
                switch (w.source) {
                  case WorkSource.research:
                    final repo = await ref.read(researchRepoProvider.future);
                    err = (await repo.setTaskStatus(
                      w.id,
                      v ? TaskStatus.done : TaskStatus.todo,
                    )).errorOrNull;
                    ref.invalidate(researchTasksProvider);
                  case WorkSource.milestone:
                    final repo = await ref.read(hackathonRepoProvider.future);
                    err = (await repo.setMilestoneDone(w.id, v)).errorOrNull;
                  case WorkSource.hackathonTask:
                    final repo = await ref.read(hackathonRepoProvider.future);
                    err = (await repo.setTaskDone(w.id, v)).errorOrNull;
                }
                if (w.source != WorkSource.research) {
                  ref.invalidate(hackathonsProvider);
                }
                return err;
              },
            ),
          gap(),
          const SectionLabel('College · due soon'),
          if (d.college.isEmpty)
            const EmptyState(message: 'Nothing due this week.'),
          for (final t in d.college)
            CheckRow(
              key: ValueKey('college-${t.id}'),
              title: t.title,
              done: t.done,
              trailing: formatDue(t.dueAt!, now),
              highlight: t.dueAt!.isBefore(now),
              onToggle: (v) async {
                final repo = await ref.read(collegeRepoProvider.future);
                final res = await repo.setDone(t.id, v);
                ref.invalidate(collegeTasksProvider);
                return res.errorOrNull;
              },
            ),
          gap(),
          const HabitsSection(),
          gap(),
          InkWell(
            onTap: () => context.push('/inbox'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Tokens.tapTarget),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SectionLabel('Inbox · ${d.inboxCount}'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
