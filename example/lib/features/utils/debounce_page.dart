import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../shared/widgets.dart';

class DebouncePage extends StatefulWidget {
  const DebouncePage({super.key});

  @override
  State<DebouncePage> createState() => _DebouncePageState();
}

class _DebouncePageState extends State<DebouncePage> {
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 300));
  int _typed = 0;
  int _calls = 0;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Debounce Demo',
      child: Column(
        children: [
          StatusBanner(
            message:
                'Characters typed: $_typed\n'
                'Potential calls: ${_debouncer.scheduled}\n'
                'Actual calls: $_calls',
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Type to search'),
            onChanged: (value) {
              setState(() => _typed = value.length);
              _debouncer.run(() async {
                await FlutterGuardScope.of(context).network.get<Object>(
                  '/search',
                  query: <String, Object?>{'q': value},
                );
                if (mounted) {
                  setState(() => _calls = _debouncer.executed);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
