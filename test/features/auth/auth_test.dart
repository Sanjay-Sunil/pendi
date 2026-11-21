import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/core/router.dart';
import 'package:pendi/features/auth/auth_repo.dart';

import '../../helpers/pump_app.dart';

class SignedOut implements AuthRepo {
  int signIns = 0;
  @override
  bool get isSignedIn => false;
  @override
  Stream<bool> get changes => const Stream.empty();
  @override
  Future<void> signIn() async => signIns++;
  @override
  Future<void> signOut() async {}
}

void main() {
  test('redirect rules', () {
    expect(authRedirect(signedIn: false, location: '/today'), '/login');
    expect(authRedirect(signedIn: false, location: '/login'), isNull);
    expect(authRedirect(signedIn: true, location: '/login'), '/today');
    expect(authRedirect(signedIn: true, location: '/cp'), isNull);
  });

  testWidgets('signed-out users land on login and can start Google sign-in', (
    tester,
  ) async {
    final auth = SignedOut();
    await pumpApp(tester, auth: auth);
    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(auth.signIns, 1);
  });

  testWidgets('demo mode opens Today directly with the banner', (tester) async {
    await pumpApp(tester);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.textContaining('DEMO MODE'), findsOneWidget);
  });
}
