import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/research.dart';
import '../../../data/providers.dart';
import '../../../domain/cp.dart';
import '../../../domain/dates.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_sheet.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/page_scaffold.dart';
import '../../../ui/section_card.dart';
import '../../../ui/section_label.dart';
import '../../../ui/streak_flame.dart';
import '../../college/providers.dart';
import '../../college/widgets/timetable_section.dart';
import '../../cp/providers.dart';
import '../../habits/habits_section.dart';
import '../../habits/providers.dart';
import '../../hackathons/providers.dart';
import '../../notes/evening_review.dart';
import '../../notes/providers.dart';
import '../../reading/widgets/reading_item_row.dart';
import '../../research/providers.dart';
import '../providers.dart';
import '../today_cache.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/check_row.dart';
import '../widgets/day_progress.dart';
import '../widgets/offline_today.dart';

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
    Widget gap() => const SizedBox(height: 16);
    final habits = ref.watch(habitsProvider).value ?? const [];
    Widget count(int n, [String? unit]) => Text(
      unit == null
          ? '$n'
          : '$n ${n == 1 ? unit.substring(0, unit.length - 1) : unit}',
      style: TextStyle(
        fontFamily: mono,
        fontSize: 11,
        color: context.colors.muted,
      ),
    );

    return PageScaffold(
      title: greeting(now),
      label: formatDayLabel(todayLocal(now)),
      maxWidth: Tokens.maxToday,
      actions: [
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(LucideIcons.settings, size: 18),
          onPressed: () => context.push('/settings'),
        ),
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
        // While loading, show the last Today we saw so opening feels instant.
        if (d == null && today.isLoading)
          if (ref.read(todayCacheProvider).load() case final cached?)
            CachedToday(snapshot: cached)
          else
            const LinearProgressIndicator(),
        if (today.hasError && d == null)
          OfflineToday(snapshot: ref.read(todayCacheProvider).load()),
        if (d != null)
          FadeIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DayProgress(
                  parts: [
                    (
                      label: 'Reading',
                      done: [for (final o in d.reading) ...o.plan.items]
                          .where((p) => p.item.isDone)
                          .length,
                      total: d.reading.fold(
                        0,
                        (n, o) => n + o.plan.items.length,
                      ),
                    ),
                    (
                      label: 'CP',
                      done: d.cp.problems
                          .where((p) => p.status == CpStatus.solved)
                          .length,
                      total: d.cp.problems.length,
                    ),
                    (
                      label: 'Habits',
                      done: habits.where((h) => h.doneOn(d.day)).length,
                      total: habits.length,
                    ),
                  ],
                ),
                gap(),
                if ((ref.watch(todayTop3Provider).value ?? const [])
                    .isNotEmpty) ...[
                  SectionCard(
                    label: 'Top 3',
                    icon: LucideIcons.target,
                    children: [
                      for (final (i, t)
                          in ref.watch(todayTop3Provider).value!.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('${i + 1}.  $t'),
                        ),
                    ],
                  ),
                  gap(),
                ],
                SectionCard(
                  label: 'Calendar',
                  icon: LucideIcons.calendar,
                  trailing: count(d.events.length),
                  children: [
                    const NowNextClass(),
                    CalendarStrip(events: d.events),
                    if (d.calendarError case final err?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          "Couldn't sync Google Calendar: $err",
                          style: TextStyle(
                            color: context.colors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                gap(),
                SectionCard(
                  label: 'Reading',
                  icon: LucideIcons.bookOpen,
                  trailing: count(
                    d.reading.fold<int>(0, (n, o) => n + o.plan.items.length),
                    'pages',
                  ),
                  children: [
                    if (d.reading.every((o) => o.plan.items.isEmpty))
                      const EmptyState(message: 'No reading due today.'),
                    for (final o in d.reading)
                      for (final p in o.plan.items)
                        ReadingItemRow(
                          key: ValueKey(p.item.id),
                          item: p.item,
                          carriedOver: p.carriedOver,
                        ),
                  ],
                ),
                gap(),
                SectionCard(
                  label: 'CP',
                  icon: LucideIcons.code,
                  trailing: StreakFlame(d.cp.streak),
                  children: [
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
                  ],
                ),
                gap(),
                SectionCard(
                  label: 'Work',
                  icon: LucideIcons.briefcase,
                  trailing: count(d.work.length),
                  children: [
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
                              final repo = await ref.read(
                                researchRepoProvider.future,
                              );
                              err = (await repo.setTaskStatus(
                                w.id,
                                v ? TaskStatus.done : TaskStatus.todo,
                              )).errorOrNull;
                              ref.invalidate(researchTasksProvider);
                            case WorkSource.milestone:
                              final repo = await ref.read(
                                hackathonRepoProvider.future,
                              );
                              err = (await repo.setMilestoneDone(
                                w.id,
                                v,
                              )).errorOrNull;
                            case WorkSource.hackathonTask:
                              final repo = await ref.read(
                                hackathonRepoProvider.future,
                              );
                              err = (await repo.setTaskDone(
                                w.id,
                                v,
                              )).errorOrNull;
                          }
                          if (w.source != WorkSource.research) {
                            ref.invalidate(hackathonsProvider);
                          }
                          return err;
                        },
                      ),
                  ],
                ),
                gap(),
                SectionCard(
                  label: 'College · due soon',
                  icon: LucideIcons.graduationCap,
                  trailing: count(d.college.length),
                  children: [
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
                          final repo = await ref.read(
                            collegeRepoProvider.future,
                          );
                          final res = await repo.setDone(t.id, v);
                          ref.invalidate(collegeTasksProvider);
                          return res.errorOrNull;
                        },
                      ),
                  ],
                ),
                gap(),
                const HabitsSection(),
                gap(),
                InkWell(
                  borderRadius: BorderRadius.circular(Tokens.radiusCard),
                  onTap: () => context.push('/inbox'),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Tokens.radiusCard),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.inbox,
                          size: 14,
                          color: context.colors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SectionLabel('Inbox · ${d.inboxCount}'),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: context.colors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
