import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pendi/integrations/sitemap.dart';

String fixture(String f) => File('test/fixtures/$f').readAsStringSync();
final base = Uri.parse('https://course.dev/');

MockClient routes(Map<String, String> pages) => MockClient((req) async {
  final body = pages[req.url.toString()];
  return body == null ? http.Response('', 404) : http.Response(body, 200);
});

const live = bool.fromEnvironment('LIVE_NETWORK');

void main() {
  test('parseLinks: same-origin pages in document order with clean titles', () {
    expect(parseLinks(fixture('course.html'), base), [
      (title: 'Introduction', url: 'https://course.dev/intro'),
      (title: 'Caching & CDNs', url: 'https://course.dev/caching'),
      (title: 'Queues', url: 'https://course.dev/queues'),
      (title: 'Sharding', url: 'https://course.dev/sharding'),
    ]);
  });

  test('parseLinks stays within the base path', () {
    const src =
        '<a href="/docs/a">A</a><a href="/blog/b">B</a><a href="/docs">Docs</a>';
    final pages = parseLinks(src, Uri.parse('https://x.dev/docs/'));
    expect(pages.map((p) => p.url), ['https://x.dev/docs/a']);
  });

  test('parseSitemap keeps same-origin locs and derives titles', () {
    expect(parseSitemap(fixture('sitemap.xml'), base), [
      (title: 'Intro', url: 'https://course.dev/intro'),
      (title: 'Load balancing', url: 'https://course.dev/load-balancing'),
    ]);
  });

  test('extract merges html order with sitemap-only pages', () async {
    final x = PageExtractor(
      client: routes({
        'https://course.dev/': fixture('course.html'),
        'https://course.dev/sitemap.xml': fixture('sitemap.xml'),
      }),
    );
    expect((await x.extract('https://course.dev/')).map((p) => p.url), [
      'https://course.dev/intro',
      'https://course.dev/caching',
      'https://course.dev/queues',
      'https://course.dev/sharding',
      'https://course.dev/load-balancing',
    ]);
  });

  test('extract works without a sitemap', () async {
    final x = PageExtractor(
      client: routes({'https://course.dev/': fixture('course.html')}),
    );
    expect(await x.extract('https://course.dev/'), hasLength(4));
  });

  Matcher code(ExtractErrorCode c) =>
      throwsA(isA<ExtractError>().having((e) => e.code, 'code', c));

  test('typed errors', () async {
    final none = PageExtractor(client: routes({}));
    expect(() => none.extract('not a url'), code(ExtractErrorCode.invalidUrl));
    expect(
      () => none.extract('https://course.dev/'),
      code(ExtractErrorCode.http),
    );
    final empty = PageExtractor(
      client: routes({'https://course.dev/': '<p>hi</p>'}),
    );
    expect(
      () => empty.extract('https://course.dev/'),
      code(ExtractErrorCode.empty),
    );
    final boom = PageExtractor(
      client: MockClient((_) => throw const SocketException('down')),
    );
    expect(
      () => boom.extract('https://course.dev/'),
      code(ExtractErrorCode.network),
    );
  });

  test('times out after 8 seconds', () {
    fakeAsync((async) {
      final slow = PageExtractor(
        client: MockClient((_) => Completer<http.Response>().future),
      );
      Object? error;
      slow.extract('https://course.dev/').catchError((Object e) {
        error = e;
        return <ExtractedPage>[];
      });
      async.elapse(const Duration(seconds: 9));
      expect((error! as ExtractError).code, ExtractErrorCode.timeout);
    });
  });

  group('live network (--dart-define=LIVE_NETWORK=true)', skip: !live, () {
    test('finds pages on saadho.arushk.tech', () async {
      expect(
        await PageExtractor().extract('https://saadho.arushk.tech/'),
        isNotEmpty,
      );
    });
    test('designed-to-scale is a client-rendered SPA and reports empty', () {
      expect(
        () => PageExtractor().extract('https://designed-to-scale.vercel.app/'),
        code(ExtractErrorCode.empty),
      );
    });
  });
}
