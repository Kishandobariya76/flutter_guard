import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../shared/widgets.dart';

class LifecyclePage extends StatelessWidget {
  const LifecyclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final guard = FlutterGuardScope.of(context);
    return DemoScaffold(
      title: 'App Lifecycle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(
            message:
                'Background the app, then return. History is recorded by '
                'AppLifecycleMonitor.\nCurrent: ${guard.lifecycle.current}',
          ),
          for (final state in guard.lifecycle.history.reversed)
            ListTile(dense: true, title: Text(state.name)),
          FilledButton(
            onPressed: () {
              guard.lifecycle.clear();
              (context as Element).markNeedsBuild();
            },
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
  }
}
