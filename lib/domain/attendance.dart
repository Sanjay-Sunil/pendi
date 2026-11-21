import 'dart:math';

sealed class SkipAdvice {
  const SkipAdvice();
  String get message;
}

/// Can miss [classes] more and stay at or above the minimum.
class CanSkip extends SkipAdvice {
  const CanSkip(this.classes);
  final int classes;
  @override
  String get message => classes == 0
      ? 'At the limit. Attend the next class.'
      : 'You can skip $classes more ${classes == 1 ? 'class' : 'classes'}.';
}

/// Must attend [classes] in a row to get back to the minimum.
class MustAttend extends SkipAdvice {
  const MustAttend(this.classes);
  final int classes;
  @override
  String get message =>
      'Attend the next $classes ${classes == 1 ? 'class' : 'classes'} to recover.';
}

class NoClassesYet extends SkipAdvice {
  const NoClassesYet();
  @override
  String get message => 'No classes yet.';
}

class CannotRecover extends SkipAdvice {
  const CannotRecover();
  @override
  String get message =>
      'Below 100% already; this course needs full attendance.';
}

/// How many more classes can be missed while staying at or above [minPct],
/// or how many must be attended to recover. Integer maths avoids float edges.
SkipAdvice canSkip(int attended, int total, int minPct) {
  if (total == 0) return const NoClassesYet();
  final p = minPct.clamp(0, 100);
  // attended / (total + k) >= p/100  ⇔  100·attended >= p·(total + k)
  if (100 * attended >= p * total) {
    if (p == 0) return const CanSkip(999);
    return CanSkip(max(0, (100 * attended - p * total) ~/ p));
  }
  if (p == 100) return const CannotRecover();
  // (attended + n) / (total + n) >= p/100  ⇔  n >= (p·total − 100·attended) / (100 − p)
  final need = p * total - 100 * attended;
  return MustAttend((need + (100 - p) - 1) ~/ (100 - p));
}

double attendancePct(int attended, int total) =>
    total == 0 ? 0 : attended * 100 / total;
