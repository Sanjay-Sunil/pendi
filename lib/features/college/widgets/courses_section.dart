import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/college.dart';
import '../../../domain/attendance.dart';
import '../../../domain/dates.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_input.dart';
import '../../../ui/app_progress_bar.dart';
import '../../../ui/app_sheet.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/section_label.dart';
import '../../college_portal/providers.dart';
import '../providers.dart';

class CoursesSection extends ConsumerWidget {
  const CoursesSection({super.key});

  void _add(BuildContext context) => showAppSheet<void>(
    context,
    title: 'New course',
    child: const _AddCourseForm(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Attendance')),
            if (ref.watch(portalSyncProvider).value case final at?)
              Text(
                'Synced ${formatTime(at)}',
                style: TextStyle(
                  fontFamily: mono,
                  fontSize: 11,
                  color: context.colors.muted,
                ),
              ),
            AppButton(
              label: 'Course',
              icon: LucideIcons.plus,
              small: true,
              variant: ButtonVariant.ghost,
              onPressed: () => _add(context),
            ),
          ],
        ),
        if (courses.isEmpty)
          EmptyState(
            message: 'Add your courses to track attendance.',
            actionLabel: 'Add a course',
            onAction: () => _add(context),
          ),
        for (final c in courses) ...[
          _CourseCard(course: c),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.colors;
    final c = course;
    final pct = attendancePct(c.attended, c.total);
    final advice = canSkip(c.attended, c.total, c.minPct);
    final low = advice is MustAttend || advice is CannotRecover;
    Future<void> mark(bool attended) async {
      await (await ref.read(collegeRepoProvider.future))
          .mark(c.id, attended: attended);
      ref.invalidate(coursesProvider);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.code == null ? c.name : '${c.code} · ${c.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${c.attended}/${c.total} · ${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: mono,
                  fontSize: 12,
                  color: low ? col.accent : col.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(
            value: c.attended,
            max: c.total,
            label: '${c.name} attendance',
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              advice.message,
              style: TextStyle(color: low ? col.accent : col.muted),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton(
                label: 'Attended',
                small: true,
                onPressed: () => mark(true),
              ),
              AppButton(
                label: 'Missed',
                small: true,
                variant: ButtonVariant.secondary,
                onPressed: () => mark(false),
              ),
              Text(
                'min ${c.minPct}%',
                style: TextStyle(
                  fontFamily: mono,
                  fontSize: 11,
                  color: col.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCourseForm extends ConsumerStatefulWidget {
  const _AddCourseForm();

  @override
  ConsumerState<_AddCourseForm> createState() => _AddCourseFormState();
}

class _AddCourseFormState extends ConsumerState<_AddCourseForm> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _min = TextEditingController(text: '80');
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _min.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final res = await (await ref.read(collegeRepoProvider.future))
        .addCourse(name: _name.text, code: _code.text, minPct: _min.text);
    if (!mounted) return;
    if (!res.isOk) return setState(() => _error = res.errorOrNull);
    ref.invalidate(coursesProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppInput(
          label: 'Course name',
          controller: _name,
          hint: 'Operating Systems',
          autofocus: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppInput(label: 'Code', controller: _code, hint: 'CS301'),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: AppInput(
                label: 'Minimum %',
                controller: _min,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: context.colors.danger)),
        const SizedBox(height: 16),
        AppButton(label: 'Add course', expand: true, onPressed: _save),
      ],
    );
  }
}
