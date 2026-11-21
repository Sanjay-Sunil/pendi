import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/cp.dart';

enum CfErrorCode { invalidHandle, network, badResponse }

class CfError implements Exception {
  const CfError(this.message, this.code);
  final String message;
  final CfErrorCode code;
  @override
  String toString() => message;
}

/// Reads accepted submissions from the public Codeforces API, cached for 10 minutes.
class CodeforcesClient {
  CodeforcesClient({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const cacheFor = Duration(minutes: 10);
  final http.Client _client;
  final DateTime Function() _now;
  final Map<String, ({DateTime at, Set<String> keys})> _cache = {};

  /// Canonical keys (e.g. `1950B`) of problems [handle] has an OK verdict on.
  Future<Set<String>> solvedKeys(String handle) async {
    final h = handle.trim();
    if (!RegExp(r'^[A-Za-z0-9_.-]{3,24}$').hasMatch(h)) {
      throw const CfError(
        'Enter a valid Codeforces handle',
        CfErrorCode.invalidHandle,
      );
    }
    final hit = _cache[h.toLowerCase()];
    if (hit != null && _now().difference(hit.at) < cacheFor) return hit.keys;

    final uri = Uri.https('codeforces.com', '/api/user.status', {
      'handle': h,
      'from': '1',
      'count': '200',
    });
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw const CfError('Could not reach Codeforces', CfErrorCode.network);
    }
    final keys = parseSolved(res.body);
    _cache[h.toLowerCase()] = (at: _now(), keys: keys);
    return keys;
  }
}

/// Validates the `user.status` payload by hand and extracts OK problems.
Set<String> parseSolved(String body) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    throw const CfError(
      'Codeforces sent an unreadable response',
      CfErrorCode.badResponse,
    );
  }
  if (json is! Map<String, Object?>) {
    throw const CfError(
      'Unexpected Codeforces response',
      CfErrorCode.badResponse,
    );
  }
  if (json['status'] != 'OK') {
    final comment = json['comment'];
    final msg = comment is String ? comment : 'Codeforces request failed';
    final code = msg.contains('not found')
        ? CfErrorCode.invalidHandle
        : CfErrorCode.badResponse;
    throw CfError(msg, code);
  }
  final result = json['result'];
  if (result is! List<Object?>) {
    throw const CfError(
      'Unexpected Codeforces response',
      CfErrorCode.badResponse,
    );
  }
  final out = <String>{};
  for (final s in result) {
    if (s is! Map<String, Object?> || s['verdict'] != 'OK') continue;
    final p = s['problem'];
    if (p is! Map<String, Object?>) continue;
    final contestId = p['contestId'];
    final index = p['index'];
    if (contestId is int && index is String) {
      out.add(canonicalKey(contestId, index));
    }
  }
  return out;
}
