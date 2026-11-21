import 'dart:async';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

typedef ExtractedPage = ({String title, String url});

enum ExtractErrorCode { invalidUrl, timeout, http, network, empty }

class ExtractError implements Exception {
  const ExtractError(this.message, this.code);
  final String message;
  final ExtractErrorCode code;
  @override
  String toString() => message;
}

const _timeout = Duration(seconds: 8);
const _userAgent = 'PendiBot/1.0 (+personal reading planner)';
final _skipExt = RegExp(
  r'\.(png|jpe?g|gif|svg|webp|ico|css|js|json|xml|pdf|zip|mp4|mp3|woff2?|ttf|txt)$',
  caseSensitive: false,
);

/// Canonical form for dedupe: no fragment, no query, no trailing slash (except root).
Uri? normalizeUrl(String href, Uri base) {
  final Uri u;
  try {
    u = base.resolve(href.trim());
  } on FormatException {
    return null;
  }
  if (u.scheme != 'http' && u.scheme != 'https') return null;
  var path = u.path.isEmpty ? '/' : u.path;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return Uri(
    scheme: u.scheme,
    host: u.host,
    port: u.hasPort ? u.port : null,
    path: path,
  );
}

bool _inScope(Uri u, Uri base) {
  if (u.origin != base.origin || _skipExt.hasMatch(u.path)) return false;
  final self = normalizeUrl(base.toString(), base);
  if (self != null && u.toString() == self.toString()) return false;
  final root = base.path.endsWith('/')
      ? base.path.substring(0, base.path.length - 1)
      : base.path;
  return root.isEmpty || u.path == root || u.path.startsWith('$root/');
}

String titleFromPath(Uri u) {
  final segs = u.pathSegments.where((s) => s.isNotEmpty);
  final slug = segs.isEmpty ? u.host : Uri.decodeComponent(segs.last);
  final words = slug
      .replaceAll(RegExp(r'\.[a-z]+$', caseSensitive: false), '')
      .replaceAll(RegExp('[-_]+'), ' ')
      .trim();
  return words.isEmpty
      ? u.toString()
      : words[0].toUpperCase() + words.substring(1);
}

String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Same-origin links under the base path, in document order, deduped.
List<ExtractedPage> parseLinks(String source, Uri base) {
  final doc = html.parse(source);
  final out = <ExtractedPage>[];
  final seen = <String>{};
  for (final a in doc.querySelectorAll('a[href]')) {
    final u = normalizeUrl(a.attributes['href'] ?? '', base);
    if (u == null || !_inScope(u, base) || !seen.add(u.toString())) continue;
    final text = _clean(a.text);
    out.add((title: text.isEmpty ? titleFromPath(u) : text, url: u.toString()));
  }
  return out;
}

/// `<loc>` entries from a sitemap under the base path, in file order.
List<ExtractedPage> parseSitemap(String source, Uri base) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(source);
  } on XmlException {
    return [];
  }
  final out = <ExtractedPage>[];
  final seen = <String>{};
  for (final loc in doc.findAllElements('loc')) {
    final u = normalizeUrl(loc.innerText, base);
    if (u == null || !_inScope(u, base) || !seen.add(u.toString())) continue;
    out.add((title: titleFromPath(u), url: u.toString()));
  }
  return out;
}

/// HTML order and titles win; sitemap-only pages are appended.
List<ExtractedPage> mergePages(
  List<ExtractedPage> fromHtml,
  List<ExtractedPage> fromSitemap,
) {
  final seen = fromHtml.map((p) => p.url).toSet();
  return [...fromHtml, ...fromSitemap.where((p) => !seen.contains(p.url))];
}

/// Fetches a course or blog index and lists its pages.
class PageExtractor {
  PageExtractor({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<http.Response> _get(Uri url) async {
    try {
      return await _client
          .get(url, headers: {'user-agent': _userAgent})
          .timeout(_timeout);
    } on TimeoutException {
      throw ExtractError(
        'Timed out after ${_timeout.inSeconds}s',
        ExtractErrorCode.timeout,
      );
    } catch (e) {
      throw ExtractError('Network error: $e', ExtractErrorCode.network);
    }
  }

  Future<List<ExtractedPage>> extract(String rawUrl) async {
    final base = Uri.tryParse(rawUrl.trim());
    if (base == null ||
        !(base.scheme == 'http' || base.scheme == 'https') ||
        base.host.isEmpty) {
      throw const ExtractError(
        'Enter a full http(s) link',
        ExtractErrorCode.invalidUrl,
      );
    }
    final results = await Future.wait([
      _get(base),
      _get(base.resolve('/sitemap.xml'))
          .then<http.Response?>((r) => r, onError: (_) => null),
    ]);
    final page = results[0]!;
    final sitemap = results[1];
    if (page.statusCode >= 400) {
      throw ExtractError(
        'Page returned HTTP ${page.statusCode}',
        ExtractErrorCode.http,
      );
    }
    final pages = mergePages(
      parseLinks(page.body, base),
      sitemap != null && sitemap.statusCode < 400
          ? parseSitemap(sitemap.body, base)
          : const [],
    );
    if (pages.isEmpty) {
      throw const ExtractError(
        'No pages found on that link',
        ExtractErrorCode.empty,
      );
    }
    return pages;
  }
}
