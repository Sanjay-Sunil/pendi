import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/providers.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_badge.dart';
import '../../../ui/app_button.dart';
import '../../../ui/app_card.dart';
import '../../../ui/app_progress_bar.dart';
import '../../../ui/app_sheet.dart';
import '../../../ui/countdown.dart';
import '../../../ui/empty_state.dart';
import '../providers.dart';
import 'add_hackathon_form.dart';

class HackathonList extends ConsumerWidget {
  const HackathonList({super.key});

  void _add(BuildContext context) => showAppSheet<void>(
    context,
    title: 'New hackathon',
    child: const AddHackathonForm(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(clockProvider)();
    final list = ref.watch(hackathonsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: 'New hackathon',
            icon: LucideIcons.plus,
            small: true,
            variant: ButtonVariant.ghost,
            onPressed: () => _add(context),
          ),
        ),
        ...list.when(
          loading: () => [const LinearProgressIndicator()],
          error: (e, _) => [Text('Could not load hackathons: $e')],
          data: (items) => items.isEmpty
              ? [
                  EmptyState(
                    message: 'No hackathons yet.',
                    actionLabel: 'Add one',
                    onAction: () => _add(context),
                  ),
                ]
              : [
                  for (final d in items) ...[
                    AppCard(
                      onTap: () =>
                          context.push('/work/hackathon/${d.hackathon.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.hackathon.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              AppBadge(
                                d.hackathon.status,
                                tone: d.hackathon.status == 'active'
                                    ? BadgeTone.accent
                                    : BadgeTone.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.nextDeadline == null
                                ? 'No deadlines yet'
                                : 'Next deadline in ${countdown(d.nextDeadline!, now)}',
                            style: TextStyle(
                              fontFamily: mono,
                              fontSize: 12,
                              color: c.muted,
                            ),
                          ),
                          if (d.milestones.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            AppProgressBar(
                              value: d.milestones.where((m) => m.done).length,
                              max: d.milestones.length,
                              label: '${d.hackathon.name} milestones',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
        ),
      ],
    );
  }
}
