import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/providers.dart';
import '../../data/repos/habit_repo.dart';
import '../../domain/dates.dart';
import '../../theme/tokens.dart';
import '../../ui/app_button.dart';
import '../../ui/app_checkbox.dart';
import '../../ui/app_input.dart';
import '../../ui/app_sheet.dart';
import '../../ui/empty_state.dart';
import '../../ui/section_card.dart';
import '../../ui/streak_flame.dart';
import '../../ui/streak_heatmap.dart';
import 'providers.dart';

class HabitsSection extends ConsumerWidget {
  const HabitsSection({super.key});

  void _manage(BuildContext context) => showAppSheet<void>(
    context,
    title: 'Habits',
    child: const _ManageHabits(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = todayLocal(ref.watch(clockProvider)());
    final habits = ref.watch(habitsProvider).value ?? const [];
    return SectionCard(
      label: 'Habits',
      icon: LucideIcons.repeat,
      trailing: AppButton(
        label: 'Manage',
        small: true,
        variant: ButtonVariant.ghost,
        onPressed: () => _manage(context),
      ),
      children: [
        if (habits.isEmpty)
          EmptyState(
            message: 'No habits yet.',
            actionLabel: 'Add a habit',
            onAction: () => _manage(context),
          ),
        for (final h in habits)
          HabitRow(key: ValueKey(h.habit.id), habit: h, today: today),
      ],
    );
  }
}

class HabitRow extends ConsumerStatefulWidget {
  const HabitRow({super.key, required this.habit, required this.today});
  final HabitWithLogs habit;
  final LocalDay today;

  @override
  ConsumerState<HabitRow> createState() => _HabitRowState();
}

class _HabitRowState extends ConsumerState<HabitRow> {
  late Set<LocalDay> _days = {...widget.habit.days};

  @override
  void didUpdateWidget(HabitRow old) {
    super.didUpdateWidget(old);
    // Only adopt server data when a fresh load arrives, not on unrelated rebuilds.
    if (!identical(old.habit, widget.habit)) _days = {...widget.habit.days};
  }

  Future<void> _toggle(bool v) async {
    setState(
      () => v ? _days.add(widget.today) : _days.remove(widget.today),
    ); // optimistic
    final res = await (await ref.read(habitRepoProvider.future))
        .setDone(widget.habit.habit.id, widget.today, v);
    if (!mounted) return;
    if (!res.isOk) {
      setState(() => v ? _days.remove(widget.today) : _days.add(widget.today));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.errorOrNull!)));
    }
    ref.invalidate(habitsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final local = HabitWithLogs(widget.habit.habit, _days);
    final week = local.week(widget.today);
    return Row(
      children: [
        Expanded(
          child: AppCheckbox(
            value: local.doneOn(widget.today),
            label: widget.habit.habit.name,
            onChanged: _toggle,
          ),
        ),
        Semantics(
          label: '${week.where((d) => d).length} of 7 days this week',
          excludeSemantics: true,
          child: Row(
            children: [
              for (final done in week)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? c.accent : c.surface2,
                    border: Border.all(color: done ? c.accent : c.border),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StreakFlame(local.streakAsOf(widget.today)),
      ],
    );
  }
}

class _ManageHabits extends ConsumerStatefulWidget {
  const _ManageHabits();

  @override
  ConsumerState<_ManageHabits> createState() => _ManageHabitsState();
}

class _ManageHabitsState extends ConsumerState<_ManageHabits> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final res = await (await ref.read(habitRepoProvider.future))
        .add(_name.text);
    if (res.isOk) _name.clear();
    ref.invalidate(habitsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final h in habits) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  h.habit.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Delete ${h.habit.name}',
                icon: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: context.colors.muted,
                ),
                onPressed: () async {
                  await (await ref.read(habitRepoProvider.future))
                      .delete(h.habit.id);
                  ref.invalidate(habitsProvider);
                },
              ),
            ],
          ),
          StreakHeatmap(
            counts: {for (final d in h.days) d: 1},
            today: todayLocal(ref.watch(clockProvider)()),
          ),
          const SizedBox(height: 20),
        ],
        AppInput(
          label: 'New habit',
          controller: _name,
          hint: 'Workout',
          onSubmitted: (_) => _add(),
        ),
        const SizedBox(height: 12),
        AppButton(label: 'Add habit', expand: true, onPressed: _add),
      ],
    );
  }
}
