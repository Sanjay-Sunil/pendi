import 'package:google_sign_in/google_sign_in.dart';

import '../core/env.dart';

Future<GoogleSignIn>? _ready;

/// The initialized Google Sign-In singleton. `initialize` must run exactly once
/// per process before any other call, including Calendar authorization after a
/// restart when no interactive sign-in has happened yet.
Future<GoogleSignIn> googleSignIn() => _ready ??= () async {
  final g = GoogleSignIn.instance;
  await g.initialize(
    serverClientId: Env.googleWebClientId.isEmpty
        ? null
        : Env.googleWebClientId,
  );
  return g;
}();
