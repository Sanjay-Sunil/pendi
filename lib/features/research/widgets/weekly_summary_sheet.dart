import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/research.dart';
import '../../../data/providers.dart';
import '../../../domain/dates.dart';
import '../../../domain/weekly_summary.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../providers.dart';

final weeklySummaryProvider = FutureProvider.autoDispose<String>((ref) async {
  final repo = await ref.watch(researchRepoProvider.future);
  final (project, logs, tasks, lib) = await (
    repo.project(),
    repo.logs(),
    repo.tasks(),
    ref.watch(researchLibraryProvider.future),
  ).wait;
  return weeklySummary(
    project: project.name,
    weekOf: todayLocal(ref.watch(clockProvider)()),
    logs: [for (final l in logs) (day: l.day, body: l.body)],
    tasks: [
      for (final t in tasks)
        if (t.doneAt != null) (title: t.title, doneAt: t.doneAt!),
    ],
    papers: [
      for (final p in lib.papers)
        if (p.status == PaperStatus.done && p.doneAt != null)
          (title: p.title, summary: p.summary, doneAt: p.doneAt!),
    ],
    experiments: [
      for (final e in lib.experiments)
        (
          title: e.title,
          day: e.day,
          hypothesis: e.hypothesis,
          result: e.result,
        ),
    ],
  );
});

class WeeklySummaryView extends ConsumerWidget {
  const WeeklySummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final md = ref.watch(weeklySummaryProvider);
    return md.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Could not build summary: $e'),
      data: (text) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.surface2,
              borderRadius: BorderRadius.circular(Tokens.radiusControl),
            ),
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: mono, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Copy',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: text));
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Share',
                  variant: ButtonVariant.secondary,
                  onPressed: () =>
                      SharePlus.instance.share(ShareParams(text: text)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
