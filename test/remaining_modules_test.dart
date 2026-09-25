import 'package:flutter_guard/flutter_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_transport.dart';

void main() {
  tearDown(() async {
    await FlutterGuard.reset();
  });

  test('paginator page, offset, and cursor load items', () async {
    Future<PageResult<int>> pageFetch(int page, int size) async {
      final start = (page - 1) * size;
      return PageResult<int>(
        items: List<int>.generate(size, (i) => start + i),
        hasMore: page < 2,
      );
    }

    final page = Paginator<int>.page(fetch: pageFetch, pageSize: 2);
    await page.load();
    expect(page.items, <int>[0, 1]);
    await page.loadMore();
    expect(page.items, <int>[0, 1, 2, 3]);
    final duplicate = page.loadMore();
    await page.loadMore();
    await duplicate;
    expect(page.items, <int>[0, 1, 2, 3]);

    final offset = Paginator<int>.offset(
      fetch: (current, limit) async {
        return PageResult<int>(
          items: List<int>.generate(limit, (i) => current + i),
          hasMore: current == 0,
        );
      },
      pageSize: 2,
    );
    await offset.load();
    await offset.loadMore();
    expect(offset.items, <int>[0, 1, 2, 3]);

    final cursor = Paginator<String>.cursor(
      fetch: (value, limit) async {
        if (value == null) {
          return const PageResult<String>(
            items: <String>['a'],
            hasMore: true,
            nextCursor: 'next',
          );
        }
        return const PageResult<String>(items: <String>['b'], hasMore: false);
      },
    );
    await cursor.load();
    await cursor.loadMore();
    expect(cursor.items, <String>['a', 'b']);
    await page.dispose();
    await offset.dispose();
    await cursor.dispose();
  });

  test('logger redacts authorization and tokens', () async {
    final (guard, _) = await createGuard();
    guard.logger.info(
      'login',
      metadata: <String, Object?>{
        'Authorization': 'Bearer super-secret',
        'password': 'hunter2',
        'accessToken': 'abc',
      },
    );
    final event = guard.logger.events.last;
    expect(event.metadata['Authorization'], '********');
    expect(event.metadata['password'], '********');
    expect(event.metadata['accessToken'], '********');
    await guard.dispose();
  });

  test('feature flags support types, rollout, and environment', () async {
    final (guard, _) = await createGuard(
      configure: (transport) => FlutterGuardConfig(
        baseUrl: 'https://api.example.com',
        transport: transport,
        environment: const EnvironmentConfig(
          environment: GuardEnvironment.development,
          applyPresets: false,
        ),
        featureFlags: FeatureFlagConfig(
          userId: 'user-1',
          appVersion: '1.4.0',
          flags: <String, FeatureFlag>{
            'new_checkout': FeatureFlag.boolean(true, key: 'new_checkout'),
            'banner': FeatureFlag.string('hello', key: 'banner'),
            'limit': FeatureFlag.integer(5, key: 'limit'),
            'ratio': FeatureFlag.number(1.5, key: 'ratio'),
            'json': FeatureFlag.json(<String, Object?>{'a': 1}, key: 'json'),
            'prod_only': FeatureFlag.boolean(
              true,
              key: 'prod_only',
              environments: const <GuardEnvironment>[
                GuardEnvironment.production,
              ],
            ),
            'none': FeatureFlag.boolean(
              true,
              key: 'none',
              rolloutPercentage: 0,
            ),
          },
        ),
      ),
    );
    expect(guard.flags.isEnabled('new_checkout'), isTrue);
    expect(guard.flags.getString('banner'), 'hello');
    expect(guard.flags.getInt('limit'), 5);
    expect(guard.flags.getDouble('ratio'), 1.5);
    expect(guard.flags.getJson('json'), <String, Object?>{'a': 1});
    expect(guard.flags.isEnabled('prod_only'), isFalse);
    expect(guard.flags.isEnabled('none'), isFalse);
    await guard.dispose();
  });

  test('debouncer and throttler drop extra invocations', () async {
    final debouncer = Debouncer(duration: const Duration(milliseconds: 20));
    var debounceRuns = 0;
    for (var i = 0; i < 5; i++) {
      debouncer.run(() => debounceRuns += 1);
    }
    expect(debouncer.scheduled, 5);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(debounceRuns, 1);

    final throttler = Throttler(duration: const Duration(milliseconds: 50));
    var throttleRuns = 0;
    for (var i = 0; i < 5; i++) {
      throttler.run(() => throttleRuns += 1);
    }
    expect(throttler.scheduled, 5);
    expect(throttleRuns, 1);
    debouncer.dispose();
  });

  test('diagnostics reset clears logs and metrics', () async {
    final (guard, transport) = await createGuard();
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{});
    };
    await guard.network.get<Object>('/ping');
    expect(guard.metrics.totalRequests, greaterThan(0));
    guard.diagnostics.reset();
    expect(guard.metrics.totalRequests, 0);
    expect(guard.logger.events, isEmpty);
    await guard.dispose();
  });
}
