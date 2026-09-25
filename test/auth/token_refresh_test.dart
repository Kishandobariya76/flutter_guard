import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_transport.dart';

void main() {
  tearDown(() async {
    await FlutterGuard.reset();
  });

  test('100 expired-token requests share one refresh', () async {
    var access = 'old-token';
    var refreshCalls = 0;
    final (guard, transport) = await createGuard(
      auth: AuthConfig(
        accessTokenProvider: () async => access,
        refreshToken: () async {
          refreshCalls += 1;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          access = 'new-token';
          return access;
        },
      ),
    );

    transport.handler = (request) async {
      final header = request.headers['Authorization'];
      if (header == 'Bearer old-token') {
        return ScriptedTransport.jsonResponse(request, <String, Object?>{
          'error': 'expired',
        }, statusCode: 401);
      }
      expect(header, 'Bearer new-token');
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'ok': true,
      });
    };

    final results = await Future.wait(
      List<Future<ApiResponse<Map<String, Object?>>>>.generate(
        100,
        (_) => guard.network.get<Map<String, Object?>>(
          '/me',
          parser: (json) => Map<String, Object?>.from(json! as Map),
        ),
      ),
    );

    expect(results.every((item) => item.data!['ok'] == true), isTrue);
    expect(refreshCalls, 1);
    expect(guard.auth.refreshCount, 1);
    expect(transport.calls, 200);
    await guard.dispose();
  });

  test('failed refresh expires the session', () async {
    final (guard, transport) = await createGuard(
      auth: AuthConfig(
        accessTokenProvider: () async => 'old-token',
        refreshToken: () async => null,
      ),
    );
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'error': 'expired',
      }, statusCode: 401);
    };
    await expectLater(
      guard.network.get<Object>('/me'),
      throwsA(isA<UnauthorizedException>()),
    );
    final session = await guard.auth.session();
    expect(session.expired, isTrue);
    await guard.dispose();
  });
}
