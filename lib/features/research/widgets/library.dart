import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/research.dart';
import '../../../data/providers.dart';
import '../../../data/repos/research_repo.dart';
import '../../../domain/dates.dart';
import '../../../domain/search.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_input.dart';
import '../../../ui/app_tabs.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/open_url.dart';
import '../../../ui/section_label.dart';
import '../providers.dart';

/// Papers, ideas and experiments, all filtered by one search box.
class LibrarySection extends ConsumerStatefulWidget {
  const LibrarySection({super.key});

  @override
  ConsumerState<LibrarySection> createState() => _LibrarySectionState();
}

class _LibrarySectionState extends ConsumerState<LibrarySection> {
  String _q = '';
  final _paper = TextEditingController();
  final _paperUrl = TextEditingController();
  final _idea = TextEditingController();
  final _expTitle = TextEditingController();
  final _expHyp = TextEditingController();

  @override
  void dispose() {
    for (final c in [_paper, _paperUrl, _idea, _expTitle, _expHyp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(
    Future<Object?> Function() action, [
    List<TextEditingController> clear = const [],
  ]) async {
    await action();
    for (final c in clear) {
      c.clear();
    }
    ref.invalidate(researchLibraryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lib = ref.watch(researchLibraryProvider).value;
    if (lib == null) return const LinearProgressIndicator();
    final papers = lib.papers
        .where((p) => matchesQuery(_q, [p.title, p.summary, p.url]))
        .toList();
    final ideas = lib.ideas.where((i) => matchesQuery(_q, [i.body])).toList();
    final exps = lib.experiments
        .where((e) => matchesQuery(_q, [e.title, e.hypothesis, e.result]))
        .toList();
    Future<ResearchRepo> repo() => ref.read(researchRepoProvider.future);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Library'),
        const SizedBox(height: 8),
        Semantics(
          label: 'Search papers, ideas and experiments',
          child: TextField(
            key: const Key('library-search'),
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(
              hintText: 'Search papers, ideas, experiments',
              prefixIcon: Icon(LucideIcons.search, size: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppTabs(
          tabs: [
            AppTab(
              'Papers (${papers.length})',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final p in papers) ...[
                    _PaperTile(
                      paper: p,
                      onChanged: () => ref.invalidate(researchLibraryProvider),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (papers.isEmpty)
                    const EmptyState(message: 'No papers match.'),
                  AppInput(label: 'Paper title', controller: _paper),
                  const SizedBox(height: 8),
                  AppInput(
                    label: 'Link (optional)',
                    controller: _paperUrl,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: 'Add paper',
                      small: true,
                      onPressed: () async => _run(
                        () async => (await repo()).addPaper(
                          _paper.text,
                          url: _paperUrl.text,
                        ),
                        [_paper, _paperUrl],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppTab(
              'Ideas (${ideas.length})',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final i in ideas)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(i.body),
                      trailing: TextButton(
                        onPressed: () => _run(
                          () async => (await repo()).setIdeaStatus(
                            i.id,
                            i.status == 'parked' ? 'exploring' : 'parked',
                          ),
                        ),
                        child: Text(i.status),
                      ),
                    ),
                  if (ideas.isEmpty)
                    const EmptyState(message: 'No ideas parked.'),
                  AppInput(
                    label: 'New idea',
                    controller: _idea,
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: 'Park idea',
                      small: true,
                      onPressed: () => _run(
                        () async => (await repo()).addIdea(_idea.text),
                        [_idea],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppTab(
              'Experiments (${exps.length})',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final e in exps) ...[
                    AppCard(
                      padding: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            formatDayLabel(e.day),
                            style: TextStyle(
                              fontFamily: mono,
                              fontSize: 11,
                              color: c.muted,
                            ),
                          ),
                          if (e.hypothesis != null)
                            Text('Hypothesis: ${e.hypothesis}'),
                          Text(
                            'Result: ${e.result ?? '—'}',
                            style: TextStyle(color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (exps.isEmpty)
                    const EmptyState(message: 'No experiments logged.'),
                  AppInput(label: 'Experiment', controller: _expTitle),
                  const SizedBox(height: 8),
                  AppInput(
                    label: 'Hypothesis',
                    controller: _expHyp,
                    maxLines: 2,
                    minLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: 'Log experiment',
                      small: true,
                      onPressed: () => _run(
                        () async => (await repo()).addExperiment(
                          title: _expTitle.text,
                          hypothesis: _expHyp.text,
                          day: todayLocal(ref.read(clockProvider)()),
                        ),
                        [_expTitle, _expHyp],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaperTile extends ConsumerWidget {
  const _PaperTile({required this.paper, required this.onChanged});
  final ResearchPaper paper;
  final VoidCallback onChanged;

  Future<void> _summary(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: paper.summary);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Summary'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          minLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null) return;
    await (await ref.read(researchRepoProvider.future))
        .updatePaper(paper.id, summary: text);
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return AppCard(
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  paper.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (paper.url != null)
                IconButton(
                  tooltip: 'Open ${paper.title}',
                  icon: Icon(
                    LucideIcons.externalLink,
                    size: 16,
                    color: c.muted,
                  ),
                  onPressed: () => openUrl(context, paper.url!),
                ),
            ],
          ),
          if (paper.summary != null)
            Text(
              paper.summary!,
              style: TextStyle(color: c.muted, fontSize: 13),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SegmentedButton<PaperStatus>(
                showSelectedIcon: false,
                segments: [
                  for (final s in PaperStatus.values)
                    ButtonSegment(value: s, label: Text(s.label)),
                ],
                selected: {paper.status},
                onSelectionChanged: (s) async {
                  await (await ref.read(researchRepoProvider.future))
                      .updatePaper(paper.id, status: s.first);
                  onChanged();
                },
              ),
              AppButton(
                label: paper.summary == null ? 'Add summary' : 'Edit summary',
                small: true,
                variant: ButtonVariant.ghost,
                onPressed: () => _summary(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
