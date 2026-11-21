import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/dates.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/section_label.dart';
import '../providers.dart';

/// Today's log with debounced autosave, plus a history of earlier days.
class DailyLog extends ConsumerStatefulWidget {
  const DailyLog({super.key});

  static const debounce = Duration(milliseconds: 800);

  @override
  ConsumerState<DailyLog> createState() => _DailyLogState();
}

class _DailyLogState extends ConsumerState<DailyLog> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  bool _loaded = false;
  String _status = '';

  LocalDay get _today => todayLocal(ref.read(clockProvider)());

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final log = await (await ref.read(researchRepoProvider.future))
          .logFor(_today);
      if (!mounted) return;
      _ctrl.text = log?.body ?? '';
      setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _changed(String _) {
    setState(() => _status = 'Editing…');
    _timer?.cancel();
    _timer = Timer(DailyLog.debounce, _save);
  }

  Future<void> _save() async {
    final res = await (await ref.read(researchRepoProvider.future))
        .saveLog(_today, _ctrl.text);
    if (!mounted) return;
    setState(
      () => _status = res.isOk ? 'Saved' : 'Not saved: ${res.errorOrNull}',
    );
    ref.invalidate(researchLogsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final history = (ref.watch(researchLogsProvider).value ?? const [])
        .where((l) => l.day != _today && l.body.trim().isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel('Log · ${formatDayLabel(_today)}')),
            Text(
              _status,
              style: TextStyle(fontFamily: mono, fontSize: 11, color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: "Today's research log",
          child: TextField(
            key: const Key('research-log'),
            controller: _ctrl,
            enabled: _loaded,
            maxLines: 8,
            minLines: 4,
            onChanged: _changed,
            decoration: const InputDecoration(
              hintText: 'What did you try, read, or learn today?',
            ),
          ),
        ),
        if (history.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'History (${history.length})',
              style: const TextStyle(fontSize: 14),
            ),
            children: [
              for (final l in history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    formatDayLabel(l.day),
                    style: TextStyle(
                      fontFamily: mono,
                      fontSize: 12,
                      color: c.muted,
                    ),
                  ),
                  subtitle: Text(
                    l.body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
