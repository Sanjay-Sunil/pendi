import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/dates.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../ui/app_button.dart';
import '../../ui/app_input.dart';
import '../../ui/section_label.dart';
import '../research/providers.dart';
import 'providers.dart';

class EveningReview extends ConsumerStatefulWidget {
  const EveningReview({super.key});

  @override
  ConsumerState<EveningReview> createState() => _EveningReviewState();
}

class _EveningReviewState extends ConsumerState<EveningReview> {
  final _reflection = TextEditingController();
  final _picks = List.generate(3, (_) => TextEditingController());
  bool _toResearch = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final note = await (await ref.read(notesRepoProvider.future)).get(_today);
      if (!mounted || note == null) return;
      _reflection.text = note.reflection;
      for (var i = 0; i < note.top3.length; i++) {
        _picks[i].text = note.top3[i];
      }
      setState(() {});
    });
  }

  LocalDay get _today => todayLocal(ref.read(clockProvider)());

  @override
  void dispose() {
    _reflection.dispose();
    for (final p in _picks) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final res = await (await ref.read(notesRepoProvider.future)).save(
      _today,
      reflection: _reflection.text,
      top3: [for (final p in _picks) p.text],
    );
    if (!res.isOk) return setState(() => _error = res.errorOrNull);
    if (_toResearch && _reflection.text.trim().isNotEmpty) {
      final repo = await ref.read(researchRepoProvider.future);
      final existing = await repo.logFor(_today);
      final body = [
        if ((existing?.body ?? '').trim().isNotEmpty) existing!.body.trim(),
        _reflection.text.trim(),
      ];
      await repo.saveLog(_today, body.join('\n'));
      ref.invalidate(researchLogsProvider);
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Good night. Saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final summary = ref.watch(daySummaryProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel('Done today'),
        const SizedBox(height: 4),
        Text(
          summary?.text ?? '…',
          key: const Key('day-summary'),
          style: TextStyle(fontFamily: mono, fontSize: 12, color: c.text),
        ),
        const SizedBox(height: 16),
        AppInput(
          label: 'One line on today',
          controller: _reflection,
          maxLength: 280,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _toResearch,
          onChanged: (v) => setState(() => _toResearch = v ?? false),
          title: const Text('Also add to research log'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        const SectionLabel("Tomorrow's top 3"),
        for (var i = 0; i < 3; i++) ...[
          const SizedBox(height: 8),
          AppInput(label: 'Pick ${i + 1}', controller: _picks[i]),
        ],
        if (_error != null) Text(_error!, style: TextStyle(color: c.danger)),
        const SizedBox(height: 16),
        AppButton(label: 'Save review', expand: true, onPressed: _save),
      ],
    );
  }
}
