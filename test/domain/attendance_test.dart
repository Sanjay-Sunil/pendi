import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/attendance.dart';

void main() {
  test('zero classes', () {
    expect(canSkip(0, 0, 75), isA<NoClassesYet>());
  });

  test('exactly at the threshold can skip none', () {
    final a = canSkip(3, 4, 75);
    expect(a, isA<CanSkip>().having((s) => s.classes, 'classes', 0));
    expect(a.message, 'At the limit. Attend the next class.');
  });

  test('above threshold', () {
    expect((canSkip(9, 10, 75) as CanSkip).classes, 2); // 9/12 = 75%
    expect((canSkip(30, 30, 75) as CanSkip).classes, 10); // 30/40
  });

  test('below threshold needs recovery', () {
    expect((canSkip(2, 4, 75) as MustAttend).classes, 4); // 6/8 = 75%
    expect((canSkip(0, 1, 75) as MustAttend).classes, 3); // 3/4
    expect(canSkip(0, 1, 75).message, 'Attend the next 3 classes to recover.');
  });

  test('extreme minimums', () {
    expect(canSkip(4, 5, 100), isA<CannotRecover>());
    expect((canSkip(5, 5, 100) as CanSkip).classes, 0);
    expect((canSkip(1, 5, 0) as CanSkip).classes, 999);
  });

  test('pct', () {
    expect(attendancePct(3, 4), 75);
    expect(attendancePct(0, 0), 0);
  });
}
