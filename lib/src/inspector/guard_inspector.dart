import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/flutter_guard.dart';
import '../diagnostics/logging/log_event.dart';
import '../diagnostics/metrics/request_metric.dart';
import '../offline/queue/offline_queued_request.dart';

/// In-app debug inspector.
///
/// ```dart
/// await GuardInspector.show(context);
/// ```
///
/// The inspector does nothing when it is disabled or when the current build
/// is a release build and [InspectorConfig.allowInRelease] is false.
class GuardInspector {
  /// Opens the inspector as a full-screen route.
  ///
  /// Returns `false` when the inspector is disabled.
  static Future<bool> show(BuildContext context, {FlutterGuard? guard}) async {
    final instance = guard ?? FlutterGuard.instance;
    if (!instance.inspectorEnabled) {
      instance.logger.warning('Inspector is disabled');
      return false;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GuardInspectorPage(guard: instance),
      ),
    );
    return true;
  }
}

/// Full-screen inspector UI.
class GuardInspectorPage extends StatefulWidget {
  /// Creates the inspector page.
  const GuardInspectorPage({super.key, required this.guard});

  /// Guard being inspected.
  final FlutterGuard guard;

  @override
  State<GuardInspectorPage> createState() => _GuardInspectorPageState();
}

class _GuardInspectorPageState extends State<GuardInspectorPage> {
  String _section = 'Overview';

  FlutterGuard get guard => widget.guard;

  @override
  Widget build(BuildContext context) {
    final sections = <String>[
      'Overview',
      'Network',
      'Requests',
      'Errors',
      'Logs',
      'Cache',
      'Offline Queue',
      'Performance',
      'Feature Flags',
      'Environment',
      'Device Information',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterGuard Inspector'),
        actions: [
          TextButton(
            onPressed: () {
              guard.diagnostics.reset();
              setState(() {});
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: ListView(
              children: [
                for (final section in sections)
                  ListTile(
                    selected: _section == section,
                    title: Text(section),
                    onTap: () => setState(() => _section = section),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildSection()),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case 'Overview':
        return _OverviewSection(guard: guard);
      case 'Network':
        return _NetworkSection(guard: guard);
      case 'Requests':
        return _RequestsSection(guard: guard, errorsOnly: false);
      case 'Errors':
        return _RequestsSection(guard: guard, errorsOnly: true);
      case 'Logs':
        return _LogsSection(guard: guard);
      case 'Cache':
        return _CacheSection(guard: guard);
      case 'Offline Queue':
        return _QueueSection(guard: guard);
      case 'Performance':
        return _PerformanceSection(guard: guard);
      case 'Feature Flags':
        return _FlagsSection(guard: guard);
      case 'Environment':
        return _EnvironmentSection(guard: guard);
      case 'Device Information':
        return _DeviceSection(guard: guard);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    final metrics = guard.metrics;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        _metric('Requests', '${metrics.totalRequests}'),
        _metric('Errors', '${metrics.failedRequests}'),
        _metric('Avg latency', '${metrics.averageDuration.inMilliseconds}ms'),
        _metric('Cache hits', '${metrics.cacheHits}'),
        _metric('Cache misses', '${metrics.cacheMisses}'),
        _metric('Queue pending', '${guard.offline.queue.pendingCount}'),
        _metric('Retries', '${metrics.retryCount}'),
        _metric('Slow requests', '${metrics.slowRequests}'),
      ],
    );
  }
}

class _NetworkSection extends StatelessWidget {
  const _NetworkSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    final samples = guard.metrics.samples.reversed.take(50).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Network', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Connectivity: ${guard.connectivity.status.name}. '
          'This is adapter connectivity, not API reachability.',
        ),
        const SizedBox(height: 12),
        if (samples.isEmpty) const Text('No requests recorded yet.'),
        for (final sample in samples) _RequestTile(sample: sample),
      ],
    );
  }
}

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({required this.guard, required this.errorsOnly});

  final FlutterGuard guard;
  final bool errorsOnly;

  @override
  Widget build(BuildContext context) {
    final samples = guard.metrics.samples
        .where((sample) => !errorsOnly || sample.failed)
        .toList()
        .reversed
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          errorsOnly ? 'Errors' : 'Requests',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (samples.isEmpty) const Text('Nothing recorded yet.'),
        for (final sample in samples)
          _RequestTile(sample: sample, detailed: true),
      ],
    );
  }
}

class _LogsSection extends StatelessWidget {
  const _LogsSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    final events = guard.logger.events.reversed.toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Logs', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (events.isEmpty) const Text('No log events.'),
        for (final event in events) _LogTile(event: event),
      ],
    );
  }
}

class _CacheSection extends StatelessWidget {
  const _CacheSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    final entries = guard.cache.entries;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Cache', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Hits ${guard.metrics.cacheHits} · Misses ${guard.metrics.cacheMisses}',
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty) const Text('Cache is empty.'),
        for (final entry in entries)
          ListTile(
            title: Text(entry.key),
            subtitle: Text(
              'status ${entry.statusCode} · fresh ${entry.isFresh()} · '
              'tags ${entry.tags.join(', ')}',
            ),
          ),
      ],
    );
  }
}

class _QueueSection extends StatelessWidget {
  const _QueueSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    final items = guard.offline.items;
    final progress = guard.offline.progress();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Offline Queue', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Queue ${progress.queue} · Completed ${progress.completed} · '
          'Processing ${progress.processing} · Pending ${progress.pending} · '
          'Failed ${progress.failed}',
        ),
        const SizedBox(height: 12),
        if (items.isEmpty) const Text('Queue is empty.'),
        for (final item in items) _QueueTile(item: item),
      ],
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    final samples = guard.metrics.samples.reversed.take(30).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Performance', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Only measured timings are shown. Radio quality is not reported.',
        ),
        const SizedBox(height: 12),
        for (final sample in samples)
          ListTile(
            title: Text('${sample.method} ${sample.url}'),
            subtitle: Text(
              '${sample.duration.inMilliseconds}ms'
              '${sample.retryDuration == null ? '' : ' · retry ${sample.retryDuration!.inMilliseconds}ms'}'
              '${sample.cacheDuration == null ? '' : ' · cache ${sample.cacheDuration!.inMilliseconds}ms'}'
              '${sample.queueDuration == null ? '' : ' · queue ${sample.queueDuration!.inMilliseconds}ms'}'
              '${sample.responseSize == null ? '' : ' · ${sample.responseSize} bytes'}',
            ),
          ),
      ],
    );
  }
}

class _FlagsSection extends StatelessWidget {
  const _FlagsSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    final flags = guard.flags.flags.values.toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Feature Flags', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (flags.isEmpty) const Text('No flags configured.'),
        for (final flag in flags)
          ListTile(
            title: Text(flag.key),
            subtitle: Text(
              '${flag.type.name} = ${flag.value} · '
              'enabled ${guard.flags.isEnabled(flag.key)} · '
              'rollout ${flag.rolloutPercentage}%',
            ),
          ),
      ],
    );
  }
}

class _EnvironmentSection extends StatelessWidget {
  const _EnvironmentSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Environment', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        _metric('Environment', guard.environment.name.toUpperCase()),
        _metric(
          'Logging',
          guard.config.diagnostics.logLevel.name.toUpperCase(),
        ),
        _metric('Inspector', guard.inspectorEnabled ? 'ENABLED' : 'DISABLED'),
        _metric('Base URL', guard.config.baseUrl ?? 'null'),
        _metric('Diagnostics', '${guard.config.diagnostics.enabled}'),
        _metric('Cache', '${guard.config.cache.enabled}'),
        _metric('Offline', '${guard.config.offline.enabled}'),
      ],
    );
  }
}

class _DeviceSection extends StatelessWidget {
  const _DeviceSection({required this.guard});

  final FlutterGuard guard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Device Information',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        _metric('Platform', defaultTargetPlatform.name),
        _metric('Web', '$kIsWeb'),
        _metric('Release mode', '$kReleaseMode'),
        _metric('Debug mode', '$kDebugMode'),
        _metric('Custom transport', '${guard.capabilities.customTransport}'),
        _metric('Persistent cache', '${guard.capabilities.persistentCache}'),
        _metric('Persistent queue', '${guard.capabilities.persistentQueue}'),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.sample, this.detailed = false});

  final RequestMetric sample;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${sample.method} ${sample.url}'),
      subtitle: Text(
        [
          '${sample.statusCode}',
          '${sample.duration.inMilliseconds}ms',
          if (sample.retryCount > 0) 'retries ${sample.retryCount}',
          if (sample.fromCache) 'cache',
          if (sample.failed) 'failed',
          if (detailed) sample.requestId,
        ].join(' · '),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.event});

  final LogEvent event;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text('[${event.level.name}] ${event.message}'),
      subtitle: event.metadata.isEmpty ? null : Text(event.metadata.toString()),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item});

  final OfflineQueuedRequest item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${item.method} ${item.path}'),
      subtitle: Text(
        '${item.status.name} · priority ${item.priority} · '
        'attempts ${item.attempts}'
        '${item.lastError == null ? '' : ' · ${item.lastError}'}',
      ),
    );
  }
}

Widget _metric(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 160, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
