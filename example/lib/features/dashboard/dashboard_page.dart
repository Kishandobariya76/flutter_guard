import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, String)>[
      ('Network', '/network', 'GET through custom methods, upload, download'),
      ('Authentication', '/auth', 'Login, expiry, single-flight refresh'),
      ('Retry', '/retry', 'Visible attempt timeline'),
      ('Request Deduplication', '/dedup', '100 callers, one transport call'),
      ('Cancellation', '/cancel', 'Pending, completed, cancelled, failed'),
      ('Cache', '/cache', 'Policies, SWR, invalidation'),
      ('Offline Queue', '/offline', 'Queue, priority, retry, cancel'),
      ('Synchronization', '/sync', 'Offline → restore → drain'),
      ('Conflict Resolution', '/conflict', 'Real resolver strategies'),
      ('Pagination', '/pagination', 'Page, offset, cursor'),
      ('Connectivity', '/connectivity', 'Online, offline, reachability'),
      ('Diagnostics', '/diagnostics', 'Metrics, logs, inspector'),
      ('Feature Flags', '/flags', 'Local flags and targeting'),
      ('Environment', '/environment', 'Development vs production presets'),
      ('Lifecycle', '/lifecycle', 'App lifecycle history'),
      ('Debounce', '/debounce', 'Typing vs actual calls'),
      ('Throttle', '/throttle', 'Repeated events vs executions'),
      ('Configuration Playground', '/playground', 'Every public option'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterGuard Demo'),
        actions: [
          IconButton(
            tooltip: 'Open inspector',
            onPressed: () => GuardInspector.show(context),
            icon: const Icon(Icons.monitor_heart_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Production Infrastructure Toolkit',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This example talks to a local DemoTransport. It does not need a '
            'production backend. Every screen calls the real FlutterGuard APIs.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Card(
              child: ListTile(
                title: Text(item.$1),
                subtitle: Text(item.$3),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(item.$2),
              ),
            ),
        ],
      ),
    );
  }
}
