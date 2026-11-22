import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../integrations/google_auth.dart';

const calendarScope = 'https://www.googleapis.com/auth/calendar';

/// Sign-in state for the router and settings. Demo mode is always signed in.
abstract class AuthRepo {
  bool get isSignedIn;
  Stream<bool> get changes;
  Future<void> signIn();
  Future<void> signOut();
}

class DemoAuthRepo implements AuthRepo {
  @override
  bool get isSignedIn => true;
  @override
  Stream<bool> get changes => const Stream.empty();
  @override
  Future<void> signIn() async {}
  @override
  Future<void> signOut() async {}
}

/// Google Sign-In (with Calendar scope) exchanged for a Supabase session.
class GoogleSupabaseAuthRepo implements AuthRepo {
  GoogleSupabaseAuthRepo(this._supabase);

  final SupabaseClient _supabase;
  Future<GoogleSignIn> _google() => googleSignIn();

  @override
  bool get isSignedIn => _supabase.auth.currentSession != null;

  @override
  Stream<bool> get changes =>
      _supabase.auth.onAuthStateChange.map((s) => s.session != null);

  @override
  Future<void> signIn() async {
    final google = await _google();
    final account = await google.authenticate(scopeHint: const [calendarScope]);
    final idToken = account.authentication.idToken;
    if (idToken == null) throw StateError('Google did not return an ID token');
    // Ask for Calendar access now so later syncs do not interrupt the user.
    await account.authorizationClient.authorizeScopes(const [calendarScope]);
    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  @override
  Future<void> signOut() async {
    await (await _google()).signOut();
    await _supabase.auth.signOut();
  }
}
