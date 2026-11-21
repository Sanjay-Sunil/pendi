import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/core/result.dart';

void main() {
  test('guard turns exceptions into errors', () async {
    final ok = await Result.guard(() async => 1);
    expect(ok.valueOrNull, 1);
    final err = await Result.guard<int>(
      () async => throw const ValidationError('Title is required'),
    );
    expect(err.errorOrNull, 'Title is required');
  });

  test('validators', () {
    expect(requireText('  hi ', 'Title'), 'hi');
    expect(() => requireText(' ', 'Title'), throwsA(isA<ValidationError>()));
    expect(requireUrl('https://x.dev/a', 'Link'), 'https://x.dev/a');
    expect(() => requireUrl('x.dev', 'Link'), throwsA(isA<ValidationError>()));
    expect(requireInt('14', 'Days', min: 1, max: 365), 14);
    expect(
      () => requireInt(0, 'Days', min: 1, max: 365),
      throwsA(isA<ValidationError>()),
    );
  });
}
