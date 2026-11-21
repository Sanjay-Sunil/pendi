import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/capture.dart';

void main() {
  test('prefix commands', () {
    expect(parseCapture('r: send results to sir'), (
      kind: CaptureKind.researchTask,
      body: 'send results to sir',
    ));
    expect(parseCapture('C:OS quiz'), (
      kind: CaptureKind.collegeTask,
      body: 'OS quiz',
    ));
    expect(parseCapture('l: https://x.dev/post'), (
      kind: CaptureKind.readingLink,
      body: 'https://x.dev/post',
    ));
    expect(parseCapture('  buy notebook  '), (
      kind: CaptureKind.inbox,
      body: 'buy notebook',
    ));
    expect(parseCapture('rust: learn traits').kind, CaptureKind.inbox);
  });
}
