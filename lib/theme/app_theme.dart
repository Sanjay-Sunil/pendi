import 'package:flutter/material.dart';

import 'tokens.dart';

const _sans = 'Geist';
const mono = 'GeistMono';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark
      ? PendiColors.dark
      : PendiColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.accentFg,
    secondary: c.accent,
    onSecondary: c.accentFg,
    error: c.danger,
    onError: c.bg,
    surface: c.surface,
    onSurface: c.text,
    surfaceContainerHighest: c.surface2,
    outline: c.border,
    outlineVariant: c.border,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _sans,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.border,
    splashFactory: InkSparkle.splashFactory,
    extensions: [c],
  );
  final text = base.textTheme.apply(bodyColor: c.text, displayColor: c.text);
  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Tokens.radiusControl),
  );
  return base.copyWith(
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 15, height: 1.6),
      headlineSmall: text.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        side: BorderSide(color: c.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: TextStyle(color: c.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.accentFg,
        minimumSize: const Size(Tokens.tapTarget, Tokens.tapTarget),
        shape: controlShape,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        backgroundColor: c.surface,
        side: BorderSide(color: c.border),
        minimumSize: const Size(Tokens.tapTarget, Tokens.tapTarget),
        shape: controlShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: const Size(Tokens.tapTarget, Tokens.tapTarget),
        shape: controlShape,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surface2,
      contentTextStyle: TextStyle(color: c.text, fontFamily: _sans),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        side: BorderSide(color: c.border),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: c.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Tokens.radiusCard),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg,
      indicatorColor: c.accentSoft,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          color: s.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 20,
          color: s.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.bg,
      indicatorColor: c.accentSoft,
      selectedIconTheme: IconThemeData(color: c.accent, size: 20),
      unselectedIconTheme: IconThemeData(color: c.muted, size: 20),
      selectedLabelTextStyle: TextStyle(color: c.accent, fontSize: 11),
      unselectedLabelTextStyle: TextStyle(color: c.muted, fontSize: 11),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.surface, elevation: 0),
    // Selected chips/segments use a soft amber tint, not a solid fill.
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.accentSoft,
      showCheckmark: false,
      side: WidgetStateBorderSide.resolveWith(
        (s) => BorderSide(
          color: s.contains(WidgetState.selected) ? c.accent : c.border,
        ),
      ),
      labelStyle: TextStyle(fontFamily: _sans, fontSize: 13, color: c.text),
      secondaryLabelStyle: TextStyle(
        fontFamily: _sans,
        fontSize: 13,
        color: c.accent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accentSoft : c.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.text,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: c.border)),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surface2,
    ),
  );
}
