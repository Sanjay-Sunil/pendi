import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/hackathon.dart';
import '../../../data/providers.dart';
import '../../../domain/dates.dart';
import '../../../domain/hackathon_template.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_checkbox.dart';
import '../../../ui/app_input.dart';
import '../../../ui/app_progress_bar.dart';
import '../../../ui/date_field.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/open_url.dart';
import '../../../ui/page_scaffold.dart';
import '../../../ui/section_label.dart';
import '../providers.dart';

class HackathonDetailScreen extends ConsumerWidget {
  const HackathonDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(hackathonDetailProvider(id));
    return Scaffold(
      appBar: AppBar(),
      body: detail.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (d) => d == null
            ? const Center(child: Text('Hackathon not found'))
            : _Body(detail: d),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.detail});
  final HackathonDetail detail;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _milestone = TextEditingController();
  final _task = TextEditingController();
  late final _team = TextEditingController(text: widget.detail.hackathon.team);
  late final _notes = TextEditingController(
    text: widget.detail.hackathon.notes,
  );
  DateTime? _milestoneDue;
  DateTime? _taskDue;

  @override
  void dispose() {
    for (final c in [_milestone, _task, _team, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _id => widget.detail.hackathon.id;

  void _refresh() {
    ref.invalidate(hackathonDetailProvider(_id));
    ref.invalidate(hackathonsProvider);
  }

  Future<void> _applyTemplate() async {
    final repo = await ref.read(hackathonRepoProvider.future);
    final today = todayLocal(ref.read(clockProvider)());
    for (final m in standardHackathon) {
      // Due 23:59 local on the offset day.
      final due = startOfDay(addDays(today, m.days + 1))
          .subtract(const Duration(minutes: 1));
      await repo.addMilestone(_id, title: m.title, dueAt: due, kind: m.kind);
    }
    _refresh();
  }

  Future<void> _addMilestone() async {
    final res = await (await ref.read(hackathonRepoProvider.future))
        .addMilestone(_id, title: _milestone.text, dueAt: _milestoneDue);
    if (res.isOk) {
      _milestone.clear();
      setState(() => _milestoneDue = null);
    }
    _refresh();
  }

  Future<void> _addTask() async {
    final res = await (await ref.read(hackathonRepoProvider.future))
        .addTask(_id, title: _task.text, dueAt: _taskDue);
    if (res.isOk) {
      _task.clear();
      setState(() => _taskDue = null);
    }
    _refresh();
  }

  Future<void> _saveInfo() async {
    await (await ref.read(hackathonRepoProvider.future)).update(_id, {
      'team': _team.text.trim().isEmpty ? null : _team.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    });
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  Future<void> _setStatus(String status) async {
    await (await ref.read(hackathonRepoProvider.future))
        .update(_id, {'status': status});
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = widget.detail;
    final h = d.hackathon;
    final now = ref.watch(clockProvider)();
    bool overdue(DateTime? due, bool done) =>
        !done && due != null && due.isBefore(now);
    String due(DateTime? t) => t == null ? 'No date' : formatDue(t, now);

    return PageScaffold(
      title: h.name,
      label: h.theme ?? 'Hackathon',
      children: [
        Row(
          children: [
            Expanded(
              child: AppProgressBar(
                value: d.milestones.where((m) => m.done).length,
                max: d.milestones.length,
                label: 'Milestone progress',
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(d.progress * 100).round()}%',
              style: TextStyle(fontFamily: mono, fontSize: 12, color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (h.url != null)
              AppButton(
                label: 'Open site',
                icon: LucideIcons.externalLink,
                small: true,
                variant: ButtonVariant.secondary,
                onPressed: () => openUrl(context, h.url!),
              ),
            for (final s in ['active', 'submitted', 'done', 'dropped'])
              if (s != h.status)
                AppButton(
                  label: 'Mark $s',
                  small: true,
                  variant: ButtonVariant.ghost,
                  onPressed: () => _setStatus(s),
                ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel('Timeline'),
        const SizedBox(height: 8),
        if (d.milestones.isEmpty)
          EmptyState(
            message: 'No milestones yet.',
            actionLabel: 'Use “Standard hackathon” template',
            onAction: _applyTemplate,
          ),
        for (final m in d.milestones)
          Row(
            children: [
              Expanded(
                child: AppCheckbox(
                  value: m.done,
                  label: m.title,
                  labelStyle: TextStyle(
                    color: overdue(m.dueAt, m.done) ? c.accent : null,
                  ),
                  onChanged: (v) async {
                    await (await ref.read(hackathonRepoProvider.future))
                        .setMilestoneDone(m.id, v);
                    _refresh();
                  },
                ),
              ),
              Text(
                due(m.dueAt),
                style: TextStyle(
                  fontFamily: mono,
                  fontSize: 12,
                  color: overdue(m.dueAt, m.done) ? c.accent : c.muted,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        AppInput(
          label: 'New milestone',
          controller: _milestone,
          hint: 'Round 2 results',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            DateTimeField(
              value: _milestoneDue,
              onChanged: (v) => setState(() => _milestoneDue = v),
            ),
            const Spacer(),
            AppButton(label: 'Add', small: true, onPressed: _addMilestone),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel('Tasks'),
        for (final t in d.tasks)
          Row(
            children: [
              Expanded(
                child: AppCheckbox(
                  value: t.done,
                  label: t.title,
                  labelStyle: TextStyle(
                    color: overdue(t.dueAt, t.done) ? c.accent : null,
                  ),
                  onChanged: (v) async {
                    await (await ref.read(hackathonRepoProvider.future))
                        .setTaskDone(t.id, v);
                    _refresh();
                  },
                ),
              ),
              if (t.dueAt != null)
                Text(
                  due(t.dueAt),
                  style: TextStyle(
                    fontFamily: mono,
                    fontSize: 12,
                    color: overdue(t.dueAt, t.done) ? c.accent : c.muted,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        AppInput(
          label: 'New task',
          controller: _task,
          hint: 'Record demo video',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            DateTimeField(
              value: _taskDue,
              onChanged: (v) => setState(() => _taskDue = v),
            ),
            const Spacer(),
            AppButton(label: 'Add', small: true, onPressed: _addTask),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel('Team and notes'),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(label: 'Team', controller: _team, hint: 'Names, roles'),
              const SizedBox(height: 12),
              AppInput(
                label: 'Notes',
                controller: _notes,
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Save',
                  small: true,
                  onPressed: _saveInfo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
