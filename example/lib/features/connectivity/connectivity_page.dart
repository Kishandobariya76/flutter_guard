import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../core/demo_session.dart';
import '../../shared/widgets.dart';

class ConnectivityPage extends StatefulWidget {
  const ConnectivityPage({super.key});

  @override
  State<ConnectivityPage> createState() => _ConnectivityPageState();
}

class _ConnectivityPageState extends State<ConnectivityPage> {
  String _reachability = 'Not measured';

  @override
  Widget build(BuildContext context) {
    final guard = FlutterGuardScope.of(context);
    return DemoScaffold(
      title: 'Connectivity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(
            message:
                'Adapter status: ${demoConnectivity.status.name}\n'
                'Monitor status: ${guard.connectivity.status.name}\n'
                'Reachability: $_reachability\n\n'
                'Connectivity is the adapter path. Reachability is an actual '
                'HTTP probe. They are not the same.',
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final status in ConnectivityStatus.values)
                FilledButton(
                  onPressed: () {
                    demoConnectivity.setStatus(status);
                    setState(() {});
                  },
                  child: Text(status.name),
                ),
              OutlinedButton(
                onPressed: () async {
                  final ok = await guard.connectivity.checkReachability(
                    uri: Uri.parse('https://invalid.invalid'),
                  );
                  setState(() {
                    _reachability = ok
                        ? 'reachable'
                        : 'unreachable (probe failed)';
                  });
                },
                child: const Text('Probe reachability'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
