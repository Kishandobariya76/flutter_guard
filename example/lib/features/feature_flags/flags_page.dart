import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../shared/widgets.dart';

class FlagsPage extends StatefulWidget {
  const FlagsPage({super.key});

  @override
  State<FlagsPage> createState() => _FlagsPageState();
}

class _FlagsPageState extends State<FlagsPage> {
  final _key = TextEditingController(text: 'new_flag');

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guard = FlutterGuardScope.of(context);
    return DemoScaffold(
      title: 'Feature Flags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _key,
            decoration: const InputDecoration(labelText: 'Flag key'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () async {
                  await guard.flags.upsert(
                    FeatureFlag.boolean(true, key: _key.text),
                  );
                  setState(() {});
                },
                child: const Text('Create boolean'),
              ),
              FilledButton(
                onPressed: () async {
                  final current = guard.flags.flags[_key.text];
                  if (current != null) {
                    await guard.flags.upsert(
                      current.copyWith(enabled: !current.enabled),
                    );
                  }
                  setState(() {});
                },
                child: const Text('Toggle'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final current = guard.flags.flags[_key.text];
                  if (current != null) {
                    await guard.flags.upsert(
                      current.copyWith(rolloutPercentage: 25),
                    );
                  }
                  setState(() {});
                },
                child: const Text('Rollout 25%'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final flag in guard.flags.flags.values)
            ListTile(
              title: Text(flag.key),
              subtitle: Text(
                '${flag.type.name}=${flag.value} enabled=${flag.enabled} '
                'eval=${guard.flags.isEnabled(flag.key)} '
                'rollout=${flag.rolloutPercentage}',
              ),
            ),
        ],
      ),
    );
  }
}
