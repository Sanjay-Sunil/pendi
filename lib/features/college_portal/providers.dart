import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/college.dart';
import '../../integrations/iiitk/attendance_client.dart';
import '../../integrations/iiitk/credentials.dart';
import '../../integrations/iiitk/moodle_client.dart';
import '../college/providers.dart';

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => const SecureCredentialStore(),
);

final lmsCredentialStoreProvider = Provider<CredentialStore>(
  (ref) => const SecureCredentialStore(prefix: 'lms'),
);

/// Builds a Moodle client for a host; overridden in tests.
final moodleClientFactoryProvider =
    Provider<MoodleClient Function(String base)>(
      (ref) =>
          (base) => MoodleClient(base: base),
    );

final attendanceClientProvider = Provider<AttendanceClient>(
  (ref) => AttendanceClient(),
);

class PortalState {
  const PortalState({this.email, this.summary, this.error, this.busy = false});
  final String? email;
  final AttendanceSummary? summary;
  final String? error;
  final bool busy;
  bool get connected => email != null;
}

/// The college account: connect (validates by fetching), refresh, disconnect.
class CollegePortal extends AsyncNotifier<PortalState> {
  @override
  Future<PortalState> build() async {
    final login = await ref.read(credentialStoreProvider).read();
    return PortalState(email: login?.email);
  }

  Future<AttendanceSummary?> _fetch(CollegeLogin login) async {
    try {
      final s = await ref
          .read(attendanceClientProvider)
          .fetch(login.email, login.password);
      state = AsyncData(PortalState(email: login.email, summary: s));
      return s;
    } on PortalError catch (e) {
      state = AsyncData(
        PortalState(email: state.value?.email, error: e.message),
      );
      return null;
    }
  }

  /// Saves the login only if the portal accepts it.
  Future<bool> connect(String email, String password) async {
    state = AsyncData(PortalState(email: state.value?.email, busy: true));
    final login = (email: email.trim(), password: password);
    final ok = await _fetch(login) != null;
    if (ok) {
      await ref.read(credentialStoreProvider).write(login);
      ref.invalidate(portalSyncProvider);
    }
    return ok;
  }

  /// Re-reads attendance with the saved login.
  Future<AttendanceSummary?> refresh() async {
    final login = await ref.read(credentialStoreProvider).read();
    if (login == null) return null;
    state = AsyncData(
      PortalState(
        email: login.email,
        summary: state.value?.summary,
        busy: true,
      ),
    );
    return _fetch(login);
  }

  Future<void> disconnect() async {
    await ref.read(credentialStoreProvider).clear();
    state = const AsyncData(PortalState());
  }
}

final collegePortalProvider = AsyncNotifierProvider<CollegePortal, PortalState>(
  CollegePortal.new,
);

/// Pulls attendance (if a college account is connected) into courses.
/// Returns when it last synced, or null when not connected / failed.
final portalSyncProvider = FutureProvider<DateTime?>((ref) async {
  final portal = ref.read(collegePortalProvider.notifier);
  final state = await ref.read(collegePortalProvider.future);
  if (!state.connected) return null;
  final summary = await portal.refresh();
  if (summary == null) return null;
  final repo = await ref.read(collegeRepoProvider.future);
  await repo.syncFromPortal([
    for (final c in summary.courses)
      (code: c.code, name: c.name, present: c.present, total: c.total),
  ]);
  ref.invalidate(coursesProvider);
  return summary.fetchedAt;
});

class LmsState {
  const LmsState({
    this.username,
    this.host,
    this.lastSync,
    this.count,
    this.error,
    this.busy = false,
  });
  final String? username;
  final String? host;
  final DateTime? lastSync;
  final int? count;
  final String? error;
  final bool busy;
  bool get connected => username != null;
}

String _taskTitle(MoodleDeadline d) =>
    d.courseShortName == null || d.courseShortName!.isEmpty
    ? d.name
    : '${d.courseShortName} · ${d.name}';

CollegeKind _kind(MoodleDeadline d) => switch (d.module) {
  'assign' => CollegeKind.assignment,
  'quiz' => CollegeKind.exam,
  _ => CollegeKind.other,
};

/// Moodle account: login is stored as `<host>|<username>` in the email slot.
class LmsAccount extends AsyncNotifier<LmsState> {
  @override
  Future<LmsState> build() async {
    final login = await ref.read(lmsCredentialStoreProvider).read();
    if (login == null) return const LmsState();
    final (host, user) = _split(login.email);
    return LmsState(username: user, host: host);
  }

  static (String, String) _split(String stored) {
    final i = stored.indexOf('|');
    return i < 0
        ? (lmsHostForEmail(stored), stored)
        : (stored.substring(0, i), stored.substring(i + 1));
  }

  Future<bool> _sync(String host, String user, String password) async {
    state = AsyncData(
      LmsState(username: state.value?.username, host: host, busy: true),
    );
    try {
      final deadlines = await ref
          .read(moodleClientFactoryProvider)(host)
          .fetch(user, password);
      final repo = await ref.read(collegeRepoProvider.future);
      await repo.syncDeadlines([
        for (final d in deadlines)
          (
            externalId: 'moodle:${d.id}',
            title: _taskTitle(d),
            kind: _kind(d),
            dueAt: d.dueAt,
          ),
      ]);
      ref.invalidate(collegeTasksProvider);
      state = AsyncData(
        LmsState(
          username: user,
          host: host,
          lastSync: DateTime.now(),
          count: deadlines.length,
        ),
      );
      return true;
    } on PortalError catch (e) {
      state = AsyncData(
        LmsState(username: state.value?.username, host: host, error: e.message),
      );
      return false;
    }
  }

  Future<bool> connect(String host, String username, String password) async {
    if (!isOfficialLms(host)) {
      state = const AsyncData(
        LmsState(
          error: 'Use an official https://lmsugYY.iiitkottayam.ac.in address',
        ),
      );
      return false;
    }
    final ok = await _sync(host, username.trim(), password);
    if (ok) {
      await ref.read(lmsCredentialStoreProvider).write((
        email: '$host|${username.trim()}',
        password: password,
      ));
    }
    return ok;
  }

  Future<bool> refresh() async {
    final login = await ref.read(lmsCredentialStoreProvider).read();
    if (login == null) return false;
    final (host, user) = _split(login.email);
    return _sync(host, user, login.password);
  }

  Future<void> disconnect() async {
    await ref.read(lmsCredentialStoreProvider).clear();
    state = const AsyncData(LmsState());
  }
}

final lmsAccountProvider = AsyncNotifierProvider<LmsAccount, LmsState>(
  LmsAccount.new,
);

/// Pulls Moodle deadlines once per app start (and on pull-to-refresh).
final lmsSyncProvider = FutureProvider<bool>((ref) async {
  final s = await ref.read(lmsAccountProvider.future);
  if (!s.connected) return false;
  return ref.read(lmsAccountProvider.notifier).refresh();
});
