import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../shared/widgets.dart';

class DedupPage extends StatefulWidget {
  const DedupPage({super.key});

  @override
  State<DedupPage> createState() => _DedupPageState();
}

class _DedupPageState extends State<DedupPage> {
  String _output = 'Fire N identical GETs with deduplicate: true.';

  Future<void> _fire(int count) async {
    final guard = FlutterGuardScope.of(context);
    guard.network.resetCounters();
    final started = DateTime.now();
    final results = await Future.wait(
      List<Future<ApiResponse<Object>>>.generate(
        count,
        (_) => guard.network.get<Object>('/dashboard', deduplicate: true),
      ),
    );
    setState(() {
      _output = [
        'Requested: $count',
        'Successful responses: ${results.length}',
        'Actual network calls: ${guard.network.transportCalls}',
        'Deduplicated joins: ${guard.network.deduplicatedJoins}',
        'Elapsed: ${DateTime.now().difference(started).inMilliseconds}ms',
      ].join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Request Deduplication',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(message: _output),
          Wrap(
            spacing: 8,
            children: [
              for (final count in <int>[1, 10, 50, 100])
                FilledButton(
                  onPressed: () => _fire(count),
                  child: Text('$count request${count == 1 ? '' : 's'}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
