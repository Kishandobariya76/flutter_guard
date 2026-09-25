import 'dart:convert';

import 'package:flutter_guard/flutter_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_transport.dart';

void main() {
  late FlutterGuard guard;
  late ScriptedTransport transport;

  setUp(() async {
    (guard, transport) = await createGuard();
  });

  tearDown(() async {
    await guard.dispose();
    await FlutterGuard.reset();
  });

  test('GET parses a typed JSON body', () async {
    transport.handler = (request) async {
      expect(request.method, 'GET');
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'id': '123',
        'name': 'Ada',
      });
    };
    final response = await guard.network.get<Map<String, Object?>>(
      '/users/123',
      parser: (json) => Map<String, Object?>.from(json! as Map),
    );
    expect(response.data!['name'], 'Ada');
    expect(response.statusCode, 200);
    expect(response.fromCache, isFalse);
    expect(response.requestId, startsWith('fg_'));
  });

  test('POST PUT PATCH DELETE HEAD and custom methods', () async {
    final methods = <String>[
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
      'HEAD',
      'OPTIONS',
    ];
    for (final method in methods) {
      transport.handler = (request) async {
        expect(request.method, method);
        return ScriptedTransport.jsonResponse(request, <String, Object?>{
          'method': method,
        });
      };
      final response = await guard.network.send<Map<String, Object?>>(
        method,
        '/echo',
        data: method == 'HEAD' ? null : <String, Object?>{'ok': true},
        parser: (json) => Map<String, Object?>.from(json! as Map),
      );
      expect(response.statusCode, 200);
    }
  });

  test('query parameters and headers are forwarded', () async {
    transport.handler = (request) async {
      expect(request.url.queryParameters['q'], 'guard');
      expect(request.headers['x-debug'], '1');
      return ScriptedTransport.jsonResponse(request, <String, Object?>{});
    };
    await guard.network.get<Object>(
      '/search',
      query: <String, Object?>{'q': 'guard'},
      headers: <String, String>{'x-debug': '1'},
    );
  });

  test('multipart upload is sent through the transport', () async {
    transport.handler = (request) async {
      expect(request.multipart, isNotNull);
      expect(request.multipart!.fields['name'], 'photo');
      expect(request.multipart!.files.single.filename, 'a.png');
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'stored': true,
      });
    };
    final response = await guard.network.upload<Map<String, Object?>>(
      '/upload',
      multipart: GuardMultipart(
        fields: const <String, String>{'name': 'photo'},
        files: <GuardMultipartFile>[
          GuardMultipartFile(
            field: 'file',
            filename: 'a.png',
            bytes: utf8.encode('png'),
          ),
        ],
      ),
      parser: (json) => Map<String, Object?>.from(json! as Map),
    );
    expect(response.data!['stored'], isTrue);
  });

  test('download returns raw bytes', () async {
    transport.handler = (request) async {
      return GuardRawResponse(
        statusCode: 200,
        headers: const <String, String>{'content-type': 'text/plain'},
        bodyBytes: utf8.encode('file-bytes'),
        requestId: request.requestId,
      );
    };
    final response = await guard.network.download('/files/a.txt');
    expect(utf8.decode(response.data!), 'file-bytes');
  });

  test('maps HTTP errors onto the exception hierarchy', () async {
    Future<void> expectStatus(int status, Type type) async {
      transport.handler = (request) async {
        return ScriptedTransport.jsonResponse(request, <String, Object?>{
          'error': status,
        }, statusCode: status);
      };
      await expectLater(
        guard.network.get<Object>('/fail/$status'),
        throwsA(
          isA<FlutterGuardException>().having(
            (error) => error.runtimeType,
            'type',
            type,
          ),
        ),
      );
    }

    await expectStatus(401, UnauthorizedException);
    await expectStatus(403, ForbiddenException);
    await expectStatus(404, NotFoundException);
    await expectStatus(422, ValidationException);
    await expectStatus(429, RateLimitException);
    await expectStatus(500, ServerException);
  });

  test('getResult captures failures without throwing', () async {
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'error': 'gone',
      }, statusCode: 404);
    };
    final result = await guard.network.getResult<Object>('/missing');
    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<NotFoundException>());
  });

  test('timeout surfaces as RequestTimeoutException', () async {
    transport.handler = (request) async {
      throw RequestTimeoutException(
        'slow',
        requestId: request.requestId,
        timeout: const Duration(milliseconds: 10),
      );
    };
    await expectLater(
      guard.network.get<Object>(
        '/slow',
        timeout: const Duration(milliseconds: 10),
      ),
      throwsA(isA<RequestTimeoutException>()),
    );
  });

  test('custom interceptor can rewrite a request', () async {
    guard.network.addInterceptor(_HeaderInterceptor());
    transport.handler = (request) async {
      expect(request.headers['x-intercepted'], 'yes');
      return ScriptedTransport.jsonResponse(request, <String, Object?>{});
    };
    await guard.network.get<Object>('/intercepted');
  });
}

class _HeaderInterceptor extends GuardInterceptor {
  @override
  Future<GuardRequest> onRequest(GuardRequest request) async {
    return request.copyWith(
      headers: <String, String>{...request.headers, 'x-intercepted': 'yes'},
    );
  }
}
