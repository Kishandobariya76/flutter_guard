import 'package:flutter/material.dart';
import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import '../../core/demo_session.dart';
import '../../shared/widgets.dart';

class ConflictPage extends StatefulWidget {
  const ConflictPage({super.key});

  @override
  State<ConflictPage> createState() => _ConflictPageState();
}

class _ConflictPageState extends State<ConflictPage> {
  String _output =
      'Each strategy runs GuardSync against a 409 from the demo API.';
  ConflictStrategy _strategy = ConflictStrategy.serverWins;

  FlutterGuard get guard => FlutterGuardScope.of(context);

  Future<void> _run() async {
    demoConnectivity.setStatus(ConnectivityStatus.online);
    await guard.offline.queue.clear();
    await guard.offline.enqueue(
      method: 'PUT',
      path: '/docs/1',
      data: <String, Object?>{'title': 'client'},
      clientUpdatedAt: DateTime.now(),
    );
    var resolverRan = false;
    guard.offline.setConflictStrategy(
      _strategy,
      resolver: (context) async {
        resolverRan = true;
        return <String, Object?>{
          'title': 'resolved',
          'from': 'customResolver',
          'server': context.serverPayload,
        };
      },
    );
    final progress = await guard.offline.sync();
    final item = guard.offline.items.single;
    setState(() {
      _output = [
        'Strategy: ${_strategy.name}',
        'Resolver ran: $resolverRan',
        'Entry status: ${item.status.name}',
        'Last error: ${item.lastError ?? 'none'}',
        'Completed: ${progress.completed} failed: ${progress.failed} '
            'needsResolution: ${progress.needsResolution}',
      ].join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Conflict Resolution',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(message: _output),
          for (final strategy in ConflictStrategy.values)
            ListTile(
              title: Text(strategy.name),
              selected: _strategy == strategy,
              onTap: () => setState(() => _strategy = strategy),
            ),
          FilledButton(
            onPressed: _run,
            child: const Text('Enqueue conflict + sync'),
          ),
        ],
      ),
    );
  }
}
