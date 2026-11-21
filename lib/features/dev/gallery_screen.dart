import 'package:flutter/material.dart';

import '../../theme/theme_toggle.dart';
import '../../ui/app_badge.dart';
import '../../ui/app_button.dart';
import '../../ui/app_card.dart';
import '../../ui/app_checkbox.dart';
import '../../ui/app_input.dart';
import '../../ui/app_progress_bar.dart';
import '../../ui/app_sheet.dart';
import '../../ui/app_tabs.dart';
import '../../ui/empty_state.dart';
import '../../ui/page_scaffold.dart';
import '../../ui/section_label.dart';

/// Hidden `/dev/ui` route showing every primitive.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _a = false;
  bool _b = true;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 24);
    return Scaffold(
      body: PageScaffold(
        title: 'UI gallery',
        label: 'Dev',
        actions: const [ThemeToggle()],
        children: [
          const SectionLabel('Buttons'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(label: 'Primary', onPressed: () {}),
              AppButton(
                label: 'Secondary',
                onPressed: () {},
                variant: ButtonVariant.secondary,
              ),
              AppButton(
                label: 'Ghost',
                onPressed: () {},
                variant: ButtonVariant.ghost,
              ),
              AppButton(
                label: 'Danger',
                onPressed: () {},
                variant: ButtonVariant.danger,
              ),
              const AppButton(label: 'Disabled', onPressed: null),
            ],
          ),
          gap,
          const SectionLabel('Fields'),
          const SizedBox(height: 8),
          const AppInput(label: 'Link', hint: 'https://…'),
          const SizedBox(height: 12),
          const AppInput(
            label: 'Note',
            hint: 'Two lines on what you learned',
            maxLines: 3,
          ),
          AppCheckbox(
            value: _a,
            onChanged: (v) => setState(() => _a = v),
            label: 'Read chapter 3',
          ),
          AppCheckbox(
            value: _b,
            onChanged: (v) => setState(() => _b = v),
            label: 'Already done',
          ),
          gap,
          const SectionLabel('Card, badge, progress'),
          const SizedBox(height: 8),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Designed to Scale')),
                    AppBadge('carried over', tone: BadgeTone.accent),
                  ],
                ),
                SizedBox(height: 12),
                AppProgressBar(value: 12, max: 30, label: 'Reading progress'),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    AppBadge('12 / 30'),
                    AppBadge('done', tone: BadgeTone.success),
                    AppBadge('overdue', tone: BadgeTone.danger),
                  ],
                ),
              ],
            ),
          ),
          gap,
          const SectionLabel('Tabs'),
          const AppTabs(
            tabs: [
              AppTab('Papers', Text('Papers panel')),
              AppTab('Ideas', Text('Ideas panel')),
              AppTab('Experiments', Text('Experiments panel')),
            ],
          ),
          gap,
          const SectionLabel('Sheet and empty state'),
          const SizedBox(height: 8),
          AppButton(
            label: 'Open sheet',
            variant: ButtonVariant.secondary,
            onPressed: () => showAppSheet<void>(
              context,
              title: 'Add source',
              child: const Text('Sheet content goes here.'),
            ),
          ),
          EmptyState(
            message: 'Nothing here yet.',
            actionLabel: 'Add one',
            onAction: () {},
          ),
        ],
      ),
    );
  }
}
