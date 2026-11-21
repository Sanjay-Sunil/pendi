import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/research.dart';
import '../../../data/providers.dart';
import '../../../domain/dates.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_checkbox.dart';
import '../../../ui/date_field.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/section_label.dart';
import '../providers.dart';

/// "Sir's tasks": quick-add (type + enter), status chip cycles todo → doing → done.
class TaskInbox extends ConsumerStatefulWidget {
  const TaskInbox({super.key});

  @override
  ConsumerState<TaskInbox> createState() => _TaskInboxState();
}

class _TaskInboxState extends ConsumerState<TaskInbox> {
  final _title = TextEditingController();
  DateTime? _due;
  int _priority = 2;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_title.text.trim().isEmpty) return;
    final res = await (await ref.read(researchRepoProvider.future))
        .addTask(_title.text, dueAt: _due, priority: _priority);
    if (!mounted) return;
    if (res.isOk) {
      _title.clear();
      setState(() => _due = null);
    }
    ref.invalidate(researchTasksProvider);
  }

  Future<void> _set(ResearchTask t, TaskStatus s) async {
    await (await ref.read(researchRepoProvider.future)).setTaskStatus(t.id, s);
    ref.invalidate(researchTasksProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = ref.watch(clockProvider)();
    final tasks = ref.watch(researchTasksProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(
          "Sir's tasks · ${tasks.where((t) => !t.isDone).length} open",
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'New task',
          child: TextField(
            key: const Key('new-task'),
            controller: _title,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: const InputDecoration(
              hintText: 'Add a task and press enter',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DateTimeField(
              value: _due,
              onChanged: (v) => setState(() => _due = v),
            ),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 1, label: Text('P1')),
                ButtonSegment(value: 2, label: Text('P2')),
                ButtonSegment(value: 3, label: Text('P3')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty) const EmptyState(message: 'No tasks from sir yet.'),
        for (final t in tasks)
          Row(
            children: [
              Expanded(
                child: AppCheckbox(
                  value: t.isDone,
                  label: t.title,
                  labelStyle: TextStyle(
                    color: t.isDone
                        ? c.muted
                        : (t.dueAt != null && t.dueAt!.isBefore(now)
                              ? c.accent
                              : null),
                    decoration: t.isDone ? TextDecoration.lineThrough : null,
                  ),
                  onChanged: (v) =>
                      _set(t, v ? TaskStatus.done : TaskStatus.todo),
                ),
              ),
              if (t.dueAt != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    formatDue(t.dueAt!, now),
                    style: TextStyle(
                      fontFamily: mono,
                      fontSize: 11,
                      color: c.muted,
                    ),
                  ),
                ),
              if (!t.isDone)
                TextButton(
                  onPressed: () => _set(
                    t,
                    t.status == TaskStatus.todo
                        ? TaskStatus.doing
                        : TaskStatus.todo,
                  ),
                  child: Text(
                    t.status == TaskStatus.doing ? 'doing' : 'P${t.priority}',
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
