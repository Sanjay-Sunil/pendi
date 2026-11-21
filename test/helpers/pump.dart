import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/theme/app_theme.dart';
import 'package:pendi/theme/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fresh SharedPreferences for each test.
Future<SharedPreferences> testPrefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Pumps [child] inside the Pendi theme at a given logical width.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.dark,
  double width = 375,
  double height = 800,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final prefs = await testPrefs();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness),
        home: Scaffold(body: child),
      ),
    ),
  );
}
