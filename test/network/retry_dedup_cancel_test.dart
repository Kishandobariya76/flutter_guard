import 'dart:async';

import 'package:flutter_guard/flutter_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_transport.dart';

void main() {
  tearDown(() async {
    await FlutterGuard.reset();
  });

  test('retries a 500 GET until success', () async {
    final (guard, transport) = await createGuard(
      configure: (transport) => FlutterGuardConfig(
        baseUrl: 'https://api.example.com',
        transport: transport,
        network: const NetworkConfig(
          retry: RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration.zero,
            jitter: false,
          ),
        ),
        environment: const EnvironmentConfig(applyPresets: false),
      ),
    );
    var attempts = 0;
    transport.handler = (request) async {
      attempts += 1;
      if (attempts < 3) {
        return ScriptedTransport.jsonResponse(request, <String, Object?>{
          'error': true,
        }, statusCode: 500);
      }
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'ok': true,
      });
    };
    final response = await guard.network.get<Map<String, Object?>>(
      '/flaky',
      parser: (json) => Map<String, Object?>.from(json! as Map),
    );
    expect(attempts, 3);
    expect(response.retryCount, 2);
    expect(response.data!['ok'], isTrue);
    await guard.dispose();
  });

  test('does not retry POST unless opted in', () async {
    final (guard, transport) = await createGuard(
      configure: (transport) => FlutterGuardConfig(
        baseUrl: 'https://api.example.com',
        transport: transport,
        network: const NetworkConfig(
          retry: RetryConfig(maxAttempts: 3, initialDelay: Duration.zero),
        ),
        environment: const EnvironmentConfig(applyPresets: false),
      ),
    );
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'error': true,
      }, statusCode: 500);
    };
    await expectLater(
      guard.network.post<Object>('/orders', data: <String, Object?>{'id': 1}),
      throwsA(isA<ServerException>()),
    );
    expect(transport.calls, 1);
    await guard.dispose();
  });

  test('100 identical requests collapse to one transport call', () async {
    final (guard, transport) = await createGuard();
    final started = Completer<void>();
    final release = Completer<void>();
    transport.handler = (request) async {
      if (!started.isCompleted) {
        started.complete();
      }
      await release.future;
      return ScriptedTransport.jsonResponse(request, <String, Object?>{'n': 1});
    };
    final futures = List<Future<ApiResponse<Object>>>.generate(
      100,
      (_) => guard.network.get<Object>('/dashboard', deduplicate: true),
    );
    await started.future;
    release.complete();
    final results = await Future.wait(futures);
    expect(results, hasLength(100));
    expect(transport.calls, 1);
    expect(guard.network.deduplicatedJoins, 99);
    await guard.dispose();
  });

  test('cancellation stops a pending request', () async {
    final (guard, transport) = await createGuard();
    final token = CancellationToken();
    final started = Completer<void>();
    transport.handler = (request) async {
      started.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      request.cancelToken?.throwIfCancelled(requestId: request.requestId);
      return ScriptedTransport.jsonResponse(request, <String, Object?>{});
    };
    final future = guard.network.get<Object>('/slow', cancelToken: token);
    await started.future;
    token.cancel();
    await expectLater(future, throwsA(isA<CancelledException>()));
    await guard.dispose();
  });
}
