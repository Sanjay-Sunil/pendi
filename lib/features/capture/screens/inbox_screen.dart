import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/college.dart';
import '../../../data/providers.dart';
import '../../../data/repos/inbox_repo.dart';
import '../../../theme/tokens.dart';
import '../../../ui/app_card.dart';
import '../../../ui/empty_state.dart';
import '../../../ui/page_scaffold.dart';
import '../../college/providers.dart';
import '../../research/providers.dart';
import '../../today/providers.dart';

/// Triage captured notes: resolve, or turn into a research / college task.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  Future<void> _act(WidgetRef ref, InboxItem item, String action) async {
    switch (action) {
      case 'research':
        await (await ref.read(researchRepoProvider.future)).addTask(item.body);
        ref.invalidate(researchTasksProvider);
      case 'college':
        await (await ref.read(collegeRepoProvider.future))
            .addTask(title: item.body, kind: CollegeKind.other);
        ref.invalidate(collegeTasksProvider);
    }
    await (await ref.read(inboxRepoProvider.future)).resolve(item.id);
    ref
      ..invalidate(inboxProvider)
      ..invalidate(todayProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(),
      body: PageScaffold(
        title: 'Inbox',
        label: '${items.length} to triage',
        maxWidth: Tokens.maxToday,
        children: [
          if (items.isEmpty) const EmptyState(message: 'Inbox zero.'),
          for (final i in items) ...[
            AppCard(
              padding: 12,
              child: Row(
                children: [
                  Expanded(child: Text(i.body)),
                  PopupMenuButton<String>(
                    tooltip: 'Triage ${i.body}',
                    onSelected: (a) => _act(ref, i, a),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'done', child: Text('Mark done')),
                      PopupMenuItem(
                        value: 'research',
                        child: Text('Make research task'),
                      ),
                      PopupMenuItem(
                        value: 'college',
                        child: Text('Make college task'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
