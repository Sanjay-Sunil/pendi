import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_badge.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_sheet.dart';
import '../../../ui/section_label.dart';
import '../providers.dart';
import 'import_sheet.dart';

class ListsSection extends ConsumerWidget {
  const ListsSection({super.key, this.onChanged});

  final VoidCallback? onChanged;

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    CpListSummary s,
  ) async {
    final ctrl = TextEditingController(text: s.list.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename list'),
        content: TextField(controller: ctrl, autofocus: true),
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
    if (name == null) return;
    await (await ref.read(cpRepoProvider.future)).rename(s.list.id, name);
    ref.invalidate(cpListsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final lists = ref.watch(cpListsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Lists')),
            AppButton(
              label: 'Import',
              icon: LucideIcons.plus,
              small: true,
              variant: ButtonVariant.ghost,
              onPressed: () => showAppSheet<void>(
                context,
                title: 'Import problems',
                child: const ImportListForm(),
              ),
            ),
          ],
        ),
        for (final s in lists) ...[
          AppCard(
            padding: 12,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.list.name, overflow: TextOverflow.ellipsis),
                      Text(
                        '${s.solved}/${s.total} solved',
                        style: TextStyle(
                          fontFamily: mono,
                          fontSize: 12,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.list.active)
                  const AppBadge('active', tone: BadgeTone.accent)
                else
                  AppButton(
                    label: 'Activate',
                    small: true,
                    variant: ButtonVariant.secondary,
                    onPressed: () async {
                      await (await ref.read(cpRepoProvider.future))
                          .activate(s.list.id);
                      ref.invalidate(cpListsProvider);
                      onChanged?.call();
                    },
                  ),
                IconButton(
                  tooltip: 'Rename ${s.list.name}',
                  icon: Icon(LucideIcons.pencil, size: 16, color: c.muted),
                  onPressed: () => _rename(context, ref, s),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
