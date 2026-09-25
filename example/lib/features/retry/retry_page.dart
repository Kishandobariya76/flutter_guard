import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../core/demo_bootstrap.dart';
import '../../core/demo_session.dart';
import '../../core/demo_transport.dart';
import '../../shared/widgets.dart';

class RetryPage extends StatefulWidget {
  const RetryPage({super.key});

  @override
  State<RetryPage> createState() => _RetryPageState();
}

class _RetryPageState extends State<RetryPage> {
  int _maxAttempts = 3;
  bool _backoff = true;
  bool _jitter = false;
  String _output = 'The flaky endpoint fails twice, then succeeds.';

  Future<void> _run() async {
    final local = DemoTransport(session: demoSession)
      ..flakyFailuresRemaining = 2;
    final isolated = await FlutterGuard.create(
      FlutterGuardConfig(
        baseUrl: 'https://demo.flutterguard.local',
        transport: local,
        connectivityAdapter: ManualConnectivityAdapter(),
        network: NetworkConfig(
          retry: RetryConfig(
            maxAttempts: _maxAttempts,
            initialDelay: const Duration(milliseconds: 80),
            exponentialBackoff: _backoff,
            jitter: _jitter,
          ),
        ),
        environment: const EnvironmentConfig(applyPresets: false),
      ),
    );
    setState(() => _output = 'Running…');
    try {
      final response = await isolated.network.get<Map<String, Object?>>(
        '/flaky',
        parser: (json) => Map<String, Object?>.from(json! as Map),
      );
      setState(() {
        _output =
            'Attempt timeline uses RetryConfig.maxAttempts=$_maxAttempts.\n'
            '${describeResponse(response)}\n'
            'Transport calls: ${local.calls}';
      });
    } catch (error) {
      setState(() => _output = describeError(error));
    } finally {
      await isolated.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Retry Demo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(message: _output),
          Text('Max attempts: $_maxAttempts'),
          Slider(
            value: _maxAttempts.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_maxAttempts',
            onChanged: (value) => setState(() => _maxAttempts = value.toInt()),
          ),
          SwitchListTile(
            title: const Text('Exponential backoff'),
            value: _backoff,
            onChanged: (value) => setState(() => _backoff = value),
          ),
          SwitchListTile(
            title: const Text('Jitter'),
            value: _jitter,
            onChanged: (value) => setState(() => _jitter = value),
          ),
          FilledButton(onPressed: _run, child: const Text('Run flaky GET')),
          const SizedBox(height: 12),
          Text('Global transport calls: ${demoTransport.calls}'),
        ],
      ),
    );
  }
}
