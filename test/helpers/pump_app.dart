import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/app.dart';
import 'package:pendi/core/router.dart';
import 'package:pendi/features/auth/auth_repo.dart';
import 'package:pendi/features/auth/providers.dart';
import 'package:pendi/theme/theme_mode_provider.dart';

import 'fakes.dart';
import 'pump.dart';

/// Pumps the whole app at a route, size and theme.
Future<void> pumpApp(
  WidgetTester tester, {
  String location = '/today',
  double width = 375,
  double height = 800,
  String theme = 'dark',
  List<Override>? overrides,
  AuthRepo? auth,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = auth ?? DemoAuthRepo();
  final storedPrefs = await testPrefs({'theme_mode': theme, ...prefs});
  await tester.pumpWidget(
    ProviderScope(
      // No automatic retries in tests: failures should surface immediately.
      retry: (_, _) => null,
      overrides: [
        sharedPrefsProvider.overrideWithValue(storedPrefs),
        authRepoProvider.overrideWithValue(repo),
        routerProvider.overrideWithValue(
          buildRouter(
            auth: auth ?? DemoAuthRepo(),
            demo: true,
            initialLocation: location,
          ),
        ),
        ...(overrides ?? testOverrides()),
      ],
      child: const PendiApp(),
    ),
  );
  await tester.pumpAndSettle();
}
