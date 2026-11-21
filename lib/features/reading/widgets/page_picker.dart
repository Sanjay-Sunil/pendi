import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens.dart';
import '../../../ui/app_checkbox.dart';

class PickablePage {
  const PickablePage(this.title, this.url, {this.selected = true});
  final String title;
  final String url;
  final bool selected;
  PickablePage toggled([bool? v]) =>
      PickablePage(title, url, selected: v ?? !selected);
}

/// Checklist of extracted pages with select-all and up/down reordering.
class PagePicker extends StatelessWidget {
  const PagePicker({super.key, required this.pages, required this.onChanged});

  final List<PickablePage> pages;
  final ValueChanged<List<PickablePage>> onChanged;

  void _move(int i, int d) {
    final j = i + d;
    if (j < 0 || j >= pages.length) return;
    final next = [...pages];
    final t = next[i];
    next[i] = next[j];
    next[j] = t;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selected = pages.where((p) => p.selected).length;
    final all = selected == pages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCheckbox(
          value: all,
          label: 'Select all ($selected/${pages.length})',
          onChanged: (_) => onChanged([for (final p in pages) p.toggled(!all)]),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(Tokens.radiusControl),
          ),
          child: Column(
            children: [
              for (var i = 0; i < pages.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.border),
                Row(
                  children: [
                    Expanded(
                      child: AppCheckbox(
                        value: pages[i].selected,
                        label: pages[i].title,
                        onChanged: (_) => onChanged([
                          for (var k = 0; k < pages.length; k++)
                            k == i ? pages[k].toggled() : pages[k],
                        ]),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Move ${pages[i].title} up',
                      icon: const Icon(LucideIcons.arrowUp, size: 16),
                      color: c.muted,
                      onPressed: i == 0 ? null : () => _move(i, -1),
                    ),
                    IconButton(
                      tooltip: 'Move ${pages[i].title} down',
                      icon: const Icon(LucideIcons.arrowDown, size: 16),
                      color: c.muted,
                      onPressed: i == pages.length - 1
                          ? null
                          : () => _move(i, 1),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
