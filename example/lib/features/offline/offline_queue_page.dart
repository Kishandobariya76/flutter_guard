import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../core/demo_session.dart';
import '../../shared/widgets.dart';

class OfflineQueuePage extends StatefulWidget {
  const OfflineQueuePage({super.key});

  @override
  State<OfflineQueuePage> createState() => _OfflineQueuePageState();
}

class _OfflineQueuePageState extends State<OfflineQueuePage> {
  String _output = 'Go offline, enqueue writes, then inspect the queue.';

  FlutterGuard get guard => FlutterGuardScope.of(context);

  void _refresh([String? message]) {
    final items = guard.offline.items;
    setState(() {
      _output = [
        ?message,
        'Connectivity: ${demoConnectivity.status.name}',
        for (final item in items)
          '${item.id} ${item.method} ${item.path} ${item.status.name} p${item.priority}',
        if (items.isEmpty) 'Queue empty',
      ].join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Offline Queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(message: _output),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () {
                  demoConnectivity.setStatus(ConnectivityStatus.offline);
                  _refresh('Simulated offline');
                },
                child: const Text('Simulate offline'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    await guard.network.post<Object>(
                      '/notes',
                      data: <String, Object?>{
                        'note': DateTime.now().toIso8601String(),
                      },
                    );
                    _refresh('Posted while online');
                  } on OfflineException catch (error) {
                    _refresh('Queued ${error.queueId}');
                  }
                },
                child: const Text('Create request'),
              ),
              FilledButton(
                onPressed: () {
                  demoConnectivity.setStatus(ConnectivityStatus.online);
                  _refresh('Connectivity restored');
                },
                child: const Text('Restore connectivity'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final items = guard.offline.items;
                  if (items.isNotEmpty) {
                    await guard.offline.setPriority(
                      items.first.id,
                      items.first.priority + 1,
                    );
                  }
                  _refresh('Priority updated');
                },
                child: const Text('Change priority'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final items = guard.offline.items;
                  if (items.isNotEmpty) {
                    await guard.offline.retry(items.first.id);
                  }
                  _refresh('Retry requested');
                },
                child: const Text('Retry'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final items = guard.offline.items;
                  if (items.isNotEmpty) {
                    await guard.offline.cancel(items.first.id);
                  }
                  _refresh('Cancelled');
                },
                child: const Text('Cancel'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await guard.offline.sync();
                  _refresh('Manual sync finished');
                },
                child: const Text('Sync'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
