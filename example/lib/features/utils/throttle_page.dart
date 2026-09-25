import 'package:flutter/material.dart';
import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import '../../shared/widgets.dart';

class ThrottlePage extends StatefulWidget {
  const ThrottlePage({super.key});

  @override
  State<ThrottlePage> createState() => _ThrottlePageState();
}

class _ThrottlePageState extends State<ThrottlePage> {
  final _throttler = Throttler(duration: const Duration(milliseconds: 400));

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Throttle Demo',
      child: Column(
        children: [
          StatusBanner(
            message:
                'Input events: ${_throttler.scheduled}\n'
                'Executed events: ${_throttler.executed}',
          ),
          FilledButton(
            onPressed: () {
              _throttler.run(() {});
              setState(() {});
            },
            child: const Text('Repeated click'),
          ),
          const SizedBox(height: 12),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                _throttler.run(() {});
                setState(() {});
              }
              return false;
            },
            child: SizedBox(
              height: 160,
              child: ListView(
                children: List<Widget>.generate(
                  20,
                  (index) => ListTile(title: Text('Scroll item $index')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
