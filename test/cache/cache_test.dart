import 'package:flutter_guard/flutter_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_transport.dart';

void main() {
  tearDown(() async {
    await FlutterGuard.reset();
  });

  test(
    'cacheFirst serves a fresh entry without a second network call',
    () async {
      final (guard, transport) = await createGuard(
        cache: const CacheConfig(defaultTtl: Duration(minutes: 10)),
      );
      transport.handler = (request) async {
        return ScriptedTransport.jsonResponse(request, <String, Object?>{
          'n': transport.calls,
        });
      };
      await guard.network.get<Object>(
        '/products',
        cachePolicy: CachePolicy.networkOnly,
        cacheTags: const <String>['products'],
      );
      final cached = await guard.network.get<Map<String, Object?>>(
        '/products',
        cachePolicy: CachePolicy.cacheFirst,
        parser: (json) => Map<String, Object?>.from(json! as Map),
      );
      expect(cached.fromCache, isTrue);
      expect(transport.calls, 1);
      await guard.dispose();
    },
  );

  test('cacheOnly throws on a miss', () async {
    final (guard, _) = await createGuard();
    await expectLater(
      guard.network.get<Object>('/missing', cachePolicy: CachePolicy.cacheOnly),
      throwsA(isA<CacheException>()),
    );
    await guard.dispose();
  });

  test('invalidate by URL and tag removes entries', () async {
    final (guard, transport) = await createGuard();
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'ok': true,
      });
    };
    await guard.network.get<Object>(
      '/products',
      cachePolicy: CachePolicy.networkOnly,
      cacheTags: const <String>['products'],
    );
    expect(guard.cache.entries, isNotEmpty);
    await guard.cache.invalidateTag('products');
    expect(guard.cache.entries, isEmpty);
    await guard.network.get<Object>(
      '/products',
      cachePolicy: CachePolicy.networkOnly,
      cacheTags: const <String>['products'],
    );
    await guard.cache.invalidate('/products');
    expect(guard.cache.entries, isEmpty);
    await guard.dispose();
  });

  test('stale-while-revalidate returns cache then refreshes', () async {
    final (guard, transport) = await createGuard(
      cache: const CacheConfig(defaultTtl: Duration(milliseconds: 1)),
    );
    var body = 'one';
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'body': body,
      });
    };
    await guard.network.get<Object>(
      '/profile',
      cachePolicy: CachePolicy.networkOnly,
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    body = 'two';
    late ApiResponse<Map<String, Object?>> fresh;
    final first = await guard.network.get<Map<String, Object?>>(
      '/profile',
      cachePolicy: CachePolicy.staleWhileRevalidate,
      parser: (json) => Map<String, Object?>.from(json! as Map),
      onRevalidate: (response) => fresh = response,
    );
    expect(first.fromCache, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(fresh.data!['body'], 'two');
    expect(fresh.fromCache, isFalse);
    await guard.dispose();
  });

  test('networkFirst falls back to cache when the network fails', () async {
    final (guard, transport) = await createGuard();
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'ok': true,
      });
    };
    await guard.network.get<Object>(
      '/catalog',
      cachePolicy: CachePolicy.networkOnly,
    );
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'error': true,
      }, statusCode: 500);
    };
    final response = await guard.network.get<Map<String, Object?>>(
      '/catalog',
      cachePolicy: CachePolicy.networkFirst,
      parser: (json) => Map<String, Object?>.from(json! as Map),
    );
    expect(response.fromCache, isTrue);
    expect(response.isStale, isTrue);
    await guard.dispose();
  });
}
