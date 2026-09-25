import 'package:flutter/material.dart';
import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import '../../shared/widgets.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  LogLevel? _level;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final guard = FlutterGuardScope.of(context);
    final metrics = guard.metrics;
    final logs = guard.logger.filter(minimum: _level, query: _query);
    return DemoScaffold(
      title: 'Diagnostics',
      actions: [
        IconButton(
          onPressed: () => GuardInspector.show(context),
          icon: const Icon(Icons.monitor_heart_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Dashboard',
            child: Text(
              'Total ${metrics.totalRequests}\n'
              'Successful ${metrics.successfulRequests}\n'
              'Failed ${metrics.failedRequests}\n'
              'Average ${metrics.averageDuration.inMilliseconds}ms\n'
              'Slow ${metrics.slowRequests}\n'
              'Retries ${metrics.retryCount}\n'
              'Cache hits ${metrics.cacheHits}\n'
              'Cache misses ${metrics.cacheMisses}\n'
              'Offline queue ${guard.offline.queue.pendingCount}',
            ),
          ),
          FilledButton(
            onPressed: () {
              guard.diagnostics.reset();
              setState(() {});
            },
            child: const Text('Reset diagnostics'),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Log viewer',
            subtitle: 'Authorization values are redacted.',
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final level in [null, ...LogLevel.values])
                      ChoiceChip(
                        label: Text(level?.name ?? 'all'),
                        selected: _level == level,
                        onSelected: (_) => setState(() => _level = level),
                      ),
                  ],
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Search'),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    guard.logger.info(
                      'Order submitted',
                      metadata: <String, Object?>{
                        'orderId': 'ord-1',
                        'Authorization': 'Bearer demo-access-token-1',
                        'password': 'should-not-appear',
                      },
                    );
                    setState(() {});
                  },
                  child: const Text('Write redacted sample log'),
                ),
                const SizedBox(height: 8),
                for (final event in logs.reversed.take(20))
                  ListTile(
                    dense: true,
                    title: Text('[${event.level.name}] ${event.message}'),
                    subtitle: Text('${event.metadata}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
