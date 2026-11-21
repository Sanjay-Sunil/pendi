import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/page_scaffold.dart';
import '../providers.dart';
import '../widgets/courses_section.dart';

class CollegeScreen extends ConsumerWidget {
  const CollegeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: 'College',
      label: 'Classes · Tasks',
      onRefresh: () async {
        ref.invalidate(coursesProvider);
        ref.invalidate(collegeTasksProvider);
      },
      children: const [CoursesSection()],
    );
  }
}
