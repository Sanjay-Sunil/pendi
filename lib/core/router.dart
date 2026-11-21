import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_repo.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/capture/capture_sheet.dart';
import '../features/capture/screens/inbox_screen.dart';
import '../features/college/screens/college_screen.dart';
import '../features/cp/screens/cp_screen.dart';
import '../features/dev/gallery_screen.dart';
import '../features/hackathons/screens/hackathon_detail_screen.dart';
import '../features/reading/screens/reading_screen.dart';
import '../features/today/screens/today_screen.dart';
import '../features/work/screens/work_screen.dart';
import '../shell/app_shell.dart';
import '../shell/demo_banner.dart';

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      pageBuilder: (_, _) => NoTransitionPage(child: screen),
    ),
  ],
);

/// Signed-out users go to /login; signed-in users never see it.
String? authRedirect({required bool signedIn, required String location}) {
  final atLogin = location == '/login';
  if (!signedIn && !atLogin && !location.startsWith('/dev')) return '/login';
  if (signedIn && atLogin) return '/today';
  return null;
}

GoRouter buildRouter({
  required AuthRepo auth,
  required bool demo,
  Listenable? refresh,
  String initialLocation = '/today',
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: refresh,
  redirect: (_, state) =>
      authRedirect(signedIn: auth.isSignedIn, location: state.matchedLocation),
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/today'),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/dev/ui', builder: (_, _) => const GalleryScreen()),
    GoRoute(path: '/inbox', builder: (_, _) => const InboxScreen()),
    GoRoute(
      path: '/work/hackathon/:id',
      builder: (_, s) => HackathonDetailScreen(id: s.pathParameters['id']!),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(
        shell: shell,
        banner: demo ? const DemoBanner() : null,
        fab: const CaptureFab(),
      ),
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

@visibleForTesting
const routerPaths = ['/today', '/reading', '/cp', '/work', '/college'];
