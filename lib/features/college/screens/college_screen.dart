import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/page_scaffold.dart';
import '../../college_portal/providers.dart';
import '../providers.dart';
import '../widgets/courses_section.dart';
import '../widgets/tasks_section.dart';

class CollegeScreen extends ConsumerWidget {
  const CollegeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick off a Moodle sync once per app start when an account is connected.
    ref.watch(lmsSyncProvider);
    return PageScaffold(
      title: 'College',
      label: 'Classes · Tasks',
      onRefresh: () async {
        ref.invalidate(portalSyncProvider);
        ref.invalidate(lmsSyncProvider);
        ref.invalidate(coursesProvider);
        ref.invalidate(collegeTasksProvider);
      },
      children: const [TasksSection(), SizedBox(height: 32), CoursesSection()],
    );
  }
}
