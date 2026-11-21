import 'package:flutter/material.dart';

/// Pendi colour tokens. Widgets read these via `context.colors`, never raw hex.
@immutable
class PendiColors extends ThemeExtension<PendiColors> {
  const PendiColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentFg,
    required this.accentSoft,
    required this.success,
    required this.danger,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentFg;
  final Color accentSoft;
  final Color success;
  final Color danger;

  static const light = PendiColors(
    bg: Color(0xFFF4EBE0),
    surface: Color(0xFFFBF6EE),
    surface2: Color(0xFFEFE4D4),
    border: Color(0xFFE0D2BD),
    text: Color(0xFF2A2118),
    muted: Color(0xFF6E5E4C),
    accent: Color(0xFFA14A07),
    accentFg: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFFDE9C7),
    success: Color(0xFF4D7C0F),
    danger: Color(0xFFB42318),
  );

  static const dark = PendiColors(
    bg: Color(0xFF0C0A09),
    surface: Color(0xFF151311),
    surface2: Color(0xFF1C1917),
    border: Color(0xFF292524),
    text: Color(0xFFEDE7DF),
    muted: Color(0xFF8F867B),
    accent: Color(0xFFF59E0B),
    accentFg: Color(0xFF1A1203),
    accentSoft: Color(0xFF2B2007),
    success: Color(0xFF84CC16),
    danger: Color(0xFFF87171),
  );

  @override
  PendiColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? text,
    Color? muted,
    Color? accent,
    Color? accentFg,
    Color? accentSoft,
    Color? success,
    Color? danger,
  }) {
    return PendiColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentFg: accentFg ?? this.accentFg,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  PendiColors lerp(PendiColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PendiColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      border: l(border, other.border),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      accent: l(accent, other.accent),
      accentFg: l(accentFg, other.accentFg),
      accentSoft: l(accentSoft, other.accentSoft),
      success: l(success, other.success),
      danger: l(danger, other.danger),
    );
  }
}

/// Spacing, radius and layout constants.
abstract final class Tokens {
  static const radiusCard = 12.0;
  static const radiusControl = 8.0;
  static const tapTarget = 48.0;
  static const pagePadPhone = 20.0;
  static const pagePadWide = 40.0;
  static const maxToday = 720.0;
  static const maxPage = 960.0;
  static const wideBreakpoint = 600.0;
  static const motion = Duration(milliseconds: 150);
}

extension PendiThemeX on BuildContext {
  PendiColors get colors => Theme.of(this).extension<PendiColors>()!;
}
