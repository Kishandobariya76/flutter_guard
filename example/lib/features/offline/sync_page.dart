import 'package:flutter/material.dart';
import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import '../../core/demo_session.dart';
import '../../shared/widgets.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  SyncProgress? _progress;

  FlutterGuard get guard => FlutterGuardScope.of(context);

  Future<void> _prepare() async {
    demoConnectivity.setStatus(ConnectivityStatus.offline);
    for (var i = 0; i < 10; i++) {
      try {
        await guard.network.post<Object>(
          '/notes',
          data: <String, Object?>{'i': i},
        );
      } on OfflineException {
        // queued
      }
    }
    setState(() => _progress = guard.offline.progress());
  }

  Future<void> _restore() async {
    demoConnectivity.setStatus(ConnectivityStatus.online);
    final progress = await guard.offline.sync();
    setState(() => _progress = progress);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return DemoScaffold(
      title: 'Synchronization',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'offline → queue → connectivity restored → automatic or manual sync',
          ),
          const SizedBox(height: 12),
          if (progress != null)
            StatusBanner(
              message:
                  'Queue: ${progress.queue}\n'
                  'Completed: ${progress.completed}\n'
                  'Processing: ${progress.processing}\n'
                  'Pending: ${progress.pending}\n'
                  'Failed: ${progress.failed}',
            ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _prepare,
                child: const Text('Queue 10 offline'),
              ),
              FilledButton(
                onPressed: _restore,
                child: const Text('Restore + sync'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
