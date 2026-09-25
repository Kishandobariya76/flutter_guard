import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../shared/widgets.dart';

class CancelPage extends StatefulWidget {
  const CancelPage({super.key});

  @override
  State<CancelPage> createState() => _CancelPageState();
}

class _CancelPageState extends State<CancelPage> {
  CancellationToken? _token;
  String _status = 'idle';

  Future<void> _start() async {
    _token = CancellationToken();
    setState(() => _status = 'pending');
    try {
      await FlutterGuardScope.of(
        context,
      ).network.get<Object>('/cancel', cancelToken: _token);
      setState(() => _status = 'completed');
    } on CancelledException {
      setState(() => _status = 'cancelled');
    } catch (error) {
      setState(() => _status = 'failed\n${describeError(error)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Request Cancellation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(message: 'Status: $_status'),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _start,
                child: const Text('Start request'),
              ),
              FilledButton(
                onPressed: () => _token?.cancel('user'),
                child: const Text('Cancel request'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
