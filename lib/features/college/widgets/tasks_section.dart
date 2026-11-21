import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/college.dart';
import '../../../data/providers.dart';
import '../../../domain/dates.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_checkbox.dart';
import '../../../ui/app_input.dart';
import '../../../ui/app_sheet.dart';
import '../../../ui/countdown.dart';
import '../../../ui/date_field.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/section_label.dart';
import '../providers.dart';

String kindLabel(CollegeKind k) => switch (k) {
  CollegeKind.assignment => 'Assignments',
  CollegeKind.exam => 'Exams',
  CollegeKind.club => 'Clubs',
  CollegeKind.other => 'Other',
};

class TasksSection extends ConsumerStatefulWidget {
  const TasksSection({super.key});

  @override
  ConsumerState<TasksSection> createState() => _TasksSectionState();
}

class _TasksSectionState extends ConsumerState<TasksSection> {
  CollegeKind? _filter;

  void _add() => showAppSheet<void>(
    context,
    title: 'New task',
    child: AddCollegeTaskForm(initialKind: _filter ?? CollegeKind.assignment),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = ref.watch(clockProvider)();
    final all = ref.watch(collegeTasksProvider).value ?? const [];
    final shown = all
        .where((t) => _filter == null || t.kind == _filter)
        .toList();
    final exams = all
        .where(
          (t) =>
              t.kind == CollegeKind.exam &&
              !t.done &&
              t.dueAt != null &&
              t.dueAt!.isAfter(now),
        )
        .take(3)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (exams.isNotEmpty) ...[
          const SectionLabel('Exams'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final e in exams)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 180,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              countdown(e.dueAt!, now),
                              style: TextStyle(
                                fontFamily: mono,
                                fontSize: 20,
                                color: c.accent,
                              ),
                            ),
                            Text(
                              formatDue(e.dueAt!, now),
                              style: TextStyle(
                                fontFamily: mono,
                                fontSize: 11,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            const Expanded(child: SectionLabel('Tasks')),
            AppButton(
              label: 'Task',
              icon: LucideIcons.plus,
              small: true,
              variant: ButtonVariant.ghost,
              onPressed: _add,
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final k in CollegeKind.values)
              ChoiceChip(
                label: Text(kindLabel(k)),
                selected: _filter == k,
                onSelected: (_) => setState(() => _filter = k),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          EmptyState(
            message: 'Nothing here.',
            actionLabel: 'Add a task',
            onAction: _add,
          ),
        for (final t in shown)
          Row(
            children: [
              Expanded(
                child: AppCheckbox(
                  value: t.done,
                  label: t.title,
                  labelStyle: TextStyle(
                    color: t.done
                        ? c.muted
                        : (t.dueAt != null && t.dueAt!.isBefore(now)
                              ? c.accent
                              : null),
                    decoration: t.done ? TextDecoration.lineThrough : null,
                  ),
                  onChanged: (v) async {
                    await (await ref.read(collegeRepoProvider.future))
                        .setDone(t.id, v);
                    ref.invalidate(collegeTasksProvider);
                  },
                ),
              ),
              if (t.dueAt != null)
                Text(
                  formatDue(t.dueAt!, now),
                  style: TextStyle(
                    fontFamily: mono,
                    fontSize: 11,
                    color: c.muted,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class AddCollegeTaskForm extends ConsumerStatefulWidget {
  const AddCollegeTaskForm({
    super.key,
    this.initialKind = CollegeKind.assignment,
    this.initialTitle,
  });

  final CollegeKind initialKind;
  final String? initialTitle;

  @override
  ConsumerState<AddCollegeTaskForm> createState() => _AddCollegeTaskFormState();
}

class _AddCollegeTaskFormState extends ConsumerState<AddCollegeTaskForm> {
  late final _title = TextEditingController(text: widget.initialTitle);
  late CollegeKind _kind = widget.initialKind;
  DateTime? _due;
  String? _courseId;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final res = await (await ref.read(collegeRepoProvider.future)).addTask(
      title: _title.text,
      kind: _kind,
      dueAt: _due,
      courseId: _courseId,
    );
    if (!mounted) return;
    if (!res.isOk) return setState(() => _error = res.errorOrNull);
    ref.invalidate(collegeTasksProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInput(
          label: 'Title',
          controller: _title,
          hint: 'DBMS assignment 3',
          autofocus: true,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final k in CollegeKind.values)
              ChoiceChip(
                label: Text(kindLabel(k)),
                selected: _kind == k,
                onSelected: (_) => setState(() => _kind = k),
              ),
          ],
        ),
        if (courses.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _courseId,
            decoration: const InputDecoration(labelText: 'Course'),
            items: [
              const DropdownMenuItem(child: Text('No course')),
              for (final c in courses)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _courseId = v),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: DateTimeField(
            value: _due,
            onChanged: (v) => setState(() => _due = v),
          ),
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: context.colors.danger)),
        const SizedBox(height: 16),
        AppButton(label: 'Add task', expand: true, onPressed: _save),
      ],
    );
  }
}
