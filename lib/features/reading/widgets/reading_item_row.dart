import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/reading.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_badge.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_checkbox.dart';
import '../../../ui/open_url.dart';
import '../providers.dart';

class ReadingItemRow extends ConsumerStatefulWidget {
  const ReadingItemRow({
    super.key,
    required this.item,
    required this.carriedOver,
  });

  final ReadingItem item;
  final bool carriedOver;

  @override
  ConsumerState<ReadingItemRow> createState() => _ReadingItemRowState();
}

class _ReadingItemRowState extends ConsumerState<ReadingItemRow> {
  late bool _done = widget.item.isDone;
  bool _noteOpen = false;
  late final _note = TextEditingController(text: widget.item.note);

  @override
  void didUpdateWidget(ReadingItemRow old) {
    super.didUpdateWidget(old);
    _done = widget.item.isDone;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool next) async {
    setState(() => _done = next); // optimistic
    final repo = await ref.read(readingRepoProvider.future);
    final res = await repo.setDone(widget.item.id, next);
    if (!mounted) return;
    if (!res.isOk) {
      setState(() => _done = !next);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.errorOrNull!)));
      return;
    }
    if (next && (widget.item.note ?? '').isEmpty) {
      setState(() => _noteOpen = true);
    }
    ref.invalidate(readingOverviewProvider);
  }

  Future<void> _saveNote() async {
    final repo = await ref.read(readingRepoProvider.future);
    final res = await repo.setNote(widget.item.id, _note.text);
    if (!mounted) return;
    if (!res.isOk) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res.errorOrNull!)));
    }
    setState(() => _noteOpen = false);
    ref.invalidate(readingOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final item = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppCheckbox(
              value: _done,
              label: item.title,
              showLabel: false,
              onChanged: _toggle,
            ),
            Expanded(
              child: InkWell(
                onTap: () => openUrl(context, item.url),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: Tokens.tapTarget,
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _done ? c.muted : c.text,
                            decoration: _done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.externalLink, size: 14, color: c.muted),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.carriedOver && !_done)
              const AppBadge('carried over', tone: BadgeTone.accent),
          ],
        ),
        if (!_noteOpen && (item.note ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44, bottom: 4),
            child: InkWell(
              onTap: () => setState(() => _noteOpen = true),
              child: Text(
                item.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.muted, fontSize: 13),
              ),
            ),
          ),
        if (_noteOpen)
          Padding(
            padding: const EdgeInsets.only(left: 44, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Note for ${item.title}',
                  child: TextField(
                    controller: _note,
                    maxLines: 2,
                    maxLength: 280,
                    decoration: const InputDecoration(
                      hintText: 'Two lines on what stuck (optional)',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppButton(
                      label: 'Save note',
                      small: true,
                      onPressed: _saveNote,
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Skip',
                      small: true,
                      variant: ButtonVariant.secondary,
                      onPressed: () => setState(() => _noteOpen = false),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
