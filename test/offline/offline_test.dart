import 'package:flutter_guard/flutter_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_transport.dart';

void main() {
  tearDown(() async {
    await FlutterGuard.reset();
  });

  test('offline mutations are queued and synchronized', () async {
    final adapter = ManualConnectivityAdapter();
    final (guard, transport) = await createGuard(connectivity: adapter);
    adapter.setStatus(ConnectivityStatus.offline);

    for (var i = 0; i < 10; i++) {
      await expectLater(
        guard.network.post<Object>('/notes', data: <String, Object?>{'i': i}),
        throwsA(
          isA<OfflineException>().having(
            (error) => error.queued,
            'queued',
            isTrue,
          ),
        ),
      );
    }
    expect(guard.offline.queue.pendingCount, 10);
    expect(transport.calls, 0);

    adapter.setStatus(ConnectivityStatus.online);
    final progress = await guard.offline.sync();
    expect(progress.completed, 10);
    expect(progress.pending, 0);
    expect(transport.calls, 10);
    await guard.dispose();
  });

  test('serverWins conflict keeps the server representation', () async {
    final (guard, transport) = await createGuard();
    await guard.offline.enqueue(
      method: 'PUT',
      path: '/docs/1',
      data: <String, Object?>{'title': 'client'},
    );
    transport.handler = (request) async {
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'title': 'server',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, statusCode: 409);
    };
    guard.offline.setConflictStrategy(ConflictStrategy.serverWins);
    final progress = await guard.offline.sync();
    expect(progress.completed, 1);
    expect(transport.calls, 1);
    await guard.dispose();
  });

  test('custom resolver actually runs and resends', () async {
    final (guard, transport) = await createGuard();
    var resolverCalls = 0;
    await guard.offline.enqueue(
      method: 'PUT',
      path: '/docs/1',
      data: <String, Object?>{'title': 'client'},
    );
    transport.handler = (request) async {
      if (request.data is Map && (request.data! as Map)['title'] == 'merged') {
        return ScriptedTransport.jsonResponse(request, <String, Object?>{
          'title': 'merged',
        });
      }
      return ScriptedTransport.jsonResponse(request, <String, Object?>{
        'title': 'server',
      }, statusCode: 409);
    };
    guard.offline.setConflictStrategy(
      ConflictStrategy.custom,
      resolver: (context) async {
        resolverCalls += 1;
        expect(context.clientPayload, isA<Map<dynamic, dynamic>>());
        return <String, Object?>{'title': 'merged'};
      },
    );
    final progress = await guard.offline.sync();
    expect(resolverCalls, 1);
    expect(progress.completed, 1);
    expect(transport.calls, 2);
    await guard.dispose();
  });

  test('connectivity is distinct from reachability', () async {
    final (guard, _) = await createGuard();
    expect(guard.connectivity.status, ConnectivityStatus.online);
    final reachable = await guard.connectivity.checkReachability(
      uri: Uri.parse('https://invalid.invalid'),
    );
    expect(reachable, isFalse);
    await guard.dispose();
  });
}
