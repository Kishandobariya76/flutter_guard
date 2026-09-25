import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

class DemoScaffold extends StatelessWidget {
  const DemoScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: ListView(padding: const EdgeInsets.all(16), children: [child]),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message),
    );
  }
}

String describeResponse(ApiResponse<dynamic> response) {
  return [
    'status ${response.statusCode}',
    'requestId ${response.requestId}',
    'duration ${response.duration.inMilliseconds}ms',
    'fromCache ${response.fromCache}',
    'stale ${response.isStale}',
    'retries ${response.retryCount}',
    'size ${response.responseSize ?? '-'}',
    'data ${response.data}',
  ].join('\n');
}

String describeError(Object error) {
  if (error is FlutterGuardException) {
    return '${error.runtimeType}: ${error.message}'
        '${error.requestId == null ? '' : '\nrequestId ${error.requestId}'}'
        '${error.statusCode == null ? '' : '\nstatus ${error.statusCode}'}'
        '${error is OfflineException && error.queued ? '\nqueued ${error.queueId}' : ''}';
  }
  return error.toString();
}
