import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import 'auth_repo.dart';

final authRepoProvider = Provider<AuthRepo>(
  (ref) => Env.isDemo
      ? DemoAuthRepo()
      : GoogleSupabaseAuthRepo(Supabase.instance.client),
);

/// Bumps whenever sign-in state changes so the router re-runs its redirect.
final authListenableProvider = Provider<Listenable>((ref) {
  final tick = ValueNotifier<int>(0);
  final sub = ref.watch(authRepoProvider).changes.listen((_) => tick.value++);
  ref.onDispose(() {
    sub.cancel();
    tick.dispose();
  });
  return tick;
});
