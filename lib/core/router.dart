import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/college/screens/college_screen.dart';
import '../features/cp/screens/cp_screen.dart';
import '../features/dev/gallery_screen.dart';
import '../features/reading/screens/reading_screen.dart';
import '../features/today/screens/today_screen.dart';
import '../features/work/screens/work_screen.dart';
import '../shell/app_shell.dart';

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      pageBuilder: (_, _) => NoTransitionPage(child: screen),
    ),
  ],
);

GoRouter buildRouter({String initialLocation = '/today'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/today'),
    GoRoute(path: '/dev/ui', builder: (_, _) => const GalleryScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        _branch('/today', const TodayScreen()),
        _branch('/reading', const ReadingScreen()),
        _branch('/cp', const CpScreen()),
        _branch('/work', const WorkScreen()),
        _branch('/college', const CollegeScreen()),
      ],
    ),
  ],
);
