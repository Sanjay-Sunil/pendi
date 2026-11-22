import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../integrations/iiitk/attendance_client.dart';
import '../../integrations/iiitk/credentials.dart';
import '../college/providers.dart';

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => const SecureCredentialStore(),
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
