import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/cp.dart';
import '../../../domain/cp.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_badge.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/open_url.dart';
import '../providers.dart';

class ProblemCard extends ConsumerStatefulWidget {
  const ProblemCard({super.key, required this.problem});

  final CpProblem problem;

  @override
  ConsumerState<ProblemCard> createState() => _ProblemCardState();
}

class _ProblemCardState extends ConsumerState<ProblemCard> {
  late CpStatus _status = widget.problem.status;
  late final _note = TextEditingController(text: widget.problem.note);
  bool _editing = false;

  @override
  void didUpdateWidget(ProblemCard old) {
    super.didUpdateWidget(old);
    if (!identical(old.problem, widget.problem)) {
      _status = widget.problem.status;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _set(CpStatus s) async {
    final prev = _status;
    setState(() => _status = s); // optimistic
    final res = await (await ref.read(cpRepoProvider.future))
        .setStatus(widget.problem.id, s);
    if (!mounted) return;
    if (!res.isOk) {
      setState(() => _status = prev);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.errorOrNull!)));
    }
    ref.invalidate(cpTodayProvider);
    ref.invalidate(cpListsProvider);
  }

  Future<void> _saveNote() async {
    await (await ref.read(cpRepoProvider.future))
        .setNote(widget.problem.id, _note.text);
    if (!mounted) return;
    setState(() => _editing = false);
    ref.invalidate(cpTodayProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = widget.problem;
    final badge = switch (_status) {
      CpStatus.solved => const AppBadge('solved', tone: BadgeTone.success),
      CpStatus.review => const AppBadge('review', tone: BadgeTone.accent),
      CpStatus.skipped => const AppBadge('skipped'),
      CpStatus.todo => null,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => openUrl(context, p.url),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: Tokens.tapTarget,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.externalLink,
                          size: 14,
                          color: c.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (p.rating != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${p.rating}',
                    style: TextStyle(
                      fontFamily: mono,
                      fontSize: 12,
                      color: c.muted,
                    ),
                  ),
                ),
              ?badge,
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Solved',
                small: true,
                icon: LucideIcons.check,
                onPressed: _status == CpStatus.solved
                    ? null
                    : () => _set(CpStatus.solved),
              ),
              AppButton(
                label: 'Stuck',
                small: true,
                variant: ButtonVariant.secondary,
                onPressed: _status == CpStatus.review
                    ? null
                    : () => _set(CpStatus.review),
              ),
              AppButton(
                label: 'Skip',
                small: true,
                variant: ButtonVariant.secondary,
                onPressed: _status == CpStatus.skipped
                    ? null
                    : () => _set(CpStatus.skipped),
              ),
              AppButton(
                label: p.note == null ? 'Add note' : 'Edit note',
                small: true,
                variant: ButtonVariant.ghost,
                onPressed: () => setState(() => _editing = !_editing),
              ),
            ],
          ),
          if (!_editing && p.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                p.note!,
                style: TextStyle(color: c.muted, fontSize: 13),
              ),
            ),
          if (_editing) ...[
            const SizedBox(height: 8),
            Semantics(
              label: 'Note for ${p.key}',
              child: TextField(
                controller: _note,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Idea, edge case, or where you got stuck',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Save note',
                small: true,
                onPressed: _saveNote,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
