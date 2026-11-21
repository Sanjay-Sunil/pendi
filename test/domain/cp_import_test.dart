import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/cp_import.dart';

void main() {
  List<String> keys(ImportResult r) =>
      r.problems.map((p) => '${p.contestId}${p.index}').toList();

  test('parses Codeforces URLs in all common shapes', () {
    final r = parseProblemList('''
https://codeforces.com/contest/1950/problem/B
https://codeforces.com/problemset/problem/4/A
codeforces.com/gym/102001/problem/c
https://codeforces.com/contest/1950/problem/B
''');
    expect(keys(r), ['1950B', '4A', '102001C']);
    expect(r.errors, isEmpty);
  });

  test('parses CSV and joined ids, skipping headers and comments', () {
    final r = parseProblemList(
      'contestId,index\n# warmups\n1950,B\n71 a\n1A\n1352C1',
    );
    expect(keys(r), ['1950B', '71A', '1A', '1352C1']);
  });

  test('reports invalid lines without failing', () {
    final r = parseProblemList(
      '1950,B\nhello world\nhttps://leetcode.com/problems/x\n4A',
    );
    expect(keys(r), ['1950B', '4A']);
    expect(r.errors.map((e) => e.line), [2, 3]);
  });

  test('parses JSON objects and pairs', () {
    final r = parseProblemList(
      '[{"contestId": 4, "index": "A", "name": "Watermelon", "rating": 800}, [1, "a"], {"x": 1}]',
    );
    expect(keys(r), ['4A', '1A']);
    expect(r.problems.first.name, 'Watermelon');
    expect(r.errors.single.line, 3);
  });

  test('reports broken JSON', () {
    expect(parseProblemList('[{oops').errors, hasLength(1));
  });
}
