import 'dart:convert';

import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import 'demo_session.dart';

/// Controllable local API used by the example application.
class DemoTransport implements GuardTransport {
  DemoTransport({required this.session});

  final DemoSession session;
  int calls = 0;
  int flakyFailuresRemaining = 2;
  final Map<String, int> _pathCalls = <String, int>{};

  int callsFor(String path) => _pathCalls[path] ?? 0;

  void resetCounters() {
    calls = 0;
    _pathCalls.clear();
    flakyFailuresRemaining = 2;
  }

  @override
  Future<GuardRawResponse> send(GuardRequest request) async {
    request.cancelToken?.throwIfCancelled(requestId: request.requestId);
    calls += 1;
    _pathCalls[request.path] = callsFor(request.path) + 1;

    final delay = request.url.queryParameters['delayMs'];
    if (delay != null) {
      await Future<void>.delayed(Duration(milliseconds: int.parse(delay)));
      request.cancelToken?.throwIfCancelled(requestId: request.requestId);
    }

    final path = request.url.path;
    if (path.endsWith('/timeout')) {
      throw RequestTimeoutException(
        'Simulated timeout',
        requestId: request.requestId,
        timeout: request.timeout,
      );
    }
    if (path.endsWith('/cancel')) {
      await Future<void>.delayed(const Duration(seconds: 8));
      request.cancelToken?.throwIfCancelled(requestId: request.requestId);
      return _json(request, <String, Object?>{'ok': true});
    }
    if (path.endsWith('/flaky')) {
      if (flakyFailuresRemaining > 0) {
        flakyFailuresRemaining -= 1;
        return _json(request, <String, Object?>{'error': 'flaky'}, status: 500);
      }
      return _json(request, <String, Object?>{
        'ok': true,
        'attempt': callsFor(request.path),
      });
    }
    if (path.endsWith('/auth/login') && request.method == 'POST') {
      session.login();
      return _json(request, <String, Object?>{
        'accessToken': session.accessToken,
        'refreshToken': session.refreshToken,
      });
    }
    if (path.endsWith('/auth/refresh') && request.method == 'POST') {
      final token = await session.refresh();
      if (token == null) {
        return _json(request, <String, Object?>{
          'error': 'no refresh',
        }, status: 401);
      }
      return _json(request, <String, Object?>{'accessToken': token});
    }
    if (path.endsWith('/auth/me')) {
      final header = request.headers['Authorization'];
      if (session.expired ||
          header == null ||
          header.contains('demo-access-token-1') && session.refreshCount > 0) {
        // handled below
      }
      if (session.accessToken == null) {
        return _json(request, <String, Object?>{
          'error': 'signed out',
        }, status: 401);
      }
      if (session.expired || header != 'Bearer ${session.accessToken}') {
        return _json(request, <String, Object?>{
          'error': 'expired',
        }, status: 401);
      }
      return _json(request, <String, Object?>{
        'user': 'demo-user',
        'token': 'redacted-in-logs',
      });
    }
    if (path.contains('/errors/')) {
      final code = int.tryParse(path.split('/').last) ?? 500;
      return _json(request, <String, Object?>{'error': code}, status: code);
    }
    if (path.endsWith('/upload') || request.multipart != null) {
      return _json(request, <String, Object?>{
        'stored': true,
        'files': request.multipart?.files.length ?? 0,
        'fields': request.multipart?.fields ?? <String, String>{},
      });
    }
    if (path.endsWith('/files/report.txt')) {
      return GuardRawResponse(
        statusCode: 200,
        headers: const <String, String>{'content-type': 'text/plain'},
        bodyBytes: utf8.encode('FlutterGuard demo file'),
        requestId: request.requestId,
      );
    }
    if (path.endsWith('/docs/1') && request.method == 'PUT') {
      final data = request.data;
      if (data is Map && data['title'] != 'resolved') {
        return _json(request, <String, Object?>{
          'title': 'server',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        }, status: 409);
      }
      return _json(request, data ?? <String, Object?>{'title': 'resolved'});
    }
    if (path.endsWith('/items')) {
      final page =
          int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
      final offset =
          int.tryParse(request.url.queryParameters['offset'] ?? '0') ?? 0;
      final cursor = request.url.queryParameters['cursor'];
      final mode = request.url.queryParameters['mode'] ?? 'page';
      if (mode == 'cursor') {
        if (cursor == null) {
          return _json(request, <String, Object?>{
            'items': <String>['cursor-a', 'cursor-b'],
            'hasMore': true,
            'nextCursor': 'c2',
          });
        }
        return _json(request, <String, Object?>{
          'items': <String>['cursor-c'],
          'hasMore': false,
        });
      }
      if (mode == 'offset') {
        return _json(request, <String, Object?>{
          'items': <String>['offset-$offset', 'offset-${offset + 1}'],
          'hasMore': offset < 2,
        });
      }
      return _json(request, <String, Object?>{
        'items': <String>['page-$page-1', 'page-$page-2'],
        'hasMore': page < 3,
      });
    }
    if (path.endsWith('/search')) {
      return _json(request, <String, Object?>{
        'q': request.url.queryParameters['q'],
        'results': <String>['result for ${request.url.queryParameters['q']}'],
      });
    }
    if (path.endsWith('/dashboard')) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _json(request, <String, Object?>{'cards': 4, 'call': calls});
    }
    if (request.method == 'HEAD') {
      return const GuardRawResponse(
        statusCode: 200,
        headers: <String, String>{'x-health': 'ok'},
        bodyBytes: <int>[],
      );
    }
    return _json(request, <String, Object?>{
      'method': request.method,
      'path': request.path,
      'query': request.query,
      'echo': request.data,
    });
  }

  @override
  Future<void> close() async {}

  GuardRawResponse _json(
    GuardRequest request,
    Object? body, {
    int status = 200,
  }) {
    return GuardRawResponse(
      statusCode: status,
      headers: const <String, String>{'content-type': 'application/json'},
      bodyBytes: utf8.encode(jsonEncode(body)),
      requestId: request.requestId,
    );
  }
}
