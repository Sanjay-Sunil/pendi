import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/app_tabs.dart';
import '../../../ui/page_scaffold.dart';
import '../../hackathons/providers.dart';
import '../../hackathons/widgets/hackathon_list.dart';
import '../../research/providers.dart';
import '../../research/widgets/research_hub.dart';

/// Work hub: hackathons and the research internship, as two segments.
class WorkScreen extends ConsumerWidget {
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: 'Work',
      label: 'Hackathons · Research',
      onRefresh: () async {
        ref.invalidate(hackathonsProvider);
        ref.invalidate(researchTasksProvider);
        ref.invalidate(researchLogsProvider);
        ref.invalidate(researchLibraryProvider);
      },
      children: const [
        AppTabs(
          tabs: [
            AppTab('Hackathons', HackathonList()),
            AppTab('Research', ResearchHub()),
          ],
        ),
      ],
    );
  }
}
