import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/repos/cp_repo.dart';
import 'package:pendi/domain/cp.dart';
import 'package:pendi/domain/cp_import.dart';
import 'package:pendi/integrations/codeforces.dart';

final fixture = File('test/fixtures/cf_user_status.json').readAsStringSync();

void main() {
  test('extracts only OK verdicts with contest problems', () {
    expect(parseSolved(fixture), {'4A', '1A'});
  });

  test('caches for 10 minutes', () async {
    var calls = 0;
    var now = DateTime(2026, 1, 1, 10);
    final cf = CodeforcesClient(
      client: MockClient((req) async {
        calls++;
        expect(req.url.queryParameters['handle'], 'tourist');
        return http.Response(fixture, 200);
      }),
      now: () => now,
    );
    await cf.solvedKeys('tourist');
    now = now.add(const Duration(minutes: 9));
    await cf.solvedKeys('Tourist');
    expect(calls, 1);
    now = now.add(const Duration(minutes: 2));
    await cf.solvedKeys('tourist');
    expect(calls, 2);
  });

  Matcher code(CfErrorCode c) =>
      throwsA(isA<CfError>().having((e) => e.code, 'code', c));

  test('fails with typed errors, never crashes', () {
    final notFound = CodeforcesClient(
      client: MockClient(
        (_) async => http.Response(
          '{"status":"FAILED","comment":"handle: User with handle zz not found"}',
          400,
        ),
      ),
    );
    expect(() => notFound.solvedKeys('zzzz'), code(CfErrorCode.invalidHandle));
    expect(() => notFound.solvedKeys('a b'), code(CfErrorCode.invalidHandle));
    final garbage = CodeforcesClient(
      client: MockClient((_) async => http.Response('<html>', 503)),
    );
    expect(() => garbage.solvedKeys('tourist'), code(CfErrorCode.badResponse));
    final down = CodeforcesClient(
      client: MockClient((_) => throw const SocketException('x')),
    );
    expect(() => down.solvedKeys('tourist'), code(CfErrorCode.network));
  });

  test('sync marks matching problems solved', () async {
    final repo = CpRepo(DemoDb());
    await repo.createList('L', parseProblemList('4A\n71A\n1A').problems);
    final n = await repo.markSolved(parseSolved(fixture));
    expect(n.valueOrNull, 2);
    final status = {for (final p in await repo.problems()) p.key: p.status};
    expect(status, {
      '4A': CpStatus.solved,
      '71A': CpStatus.todo,
      '1A': CpStatus.solved,
    });
    expect((await repo.markSolved(parseSolved(fixture))).valueOrNull, 0);
  });
}
