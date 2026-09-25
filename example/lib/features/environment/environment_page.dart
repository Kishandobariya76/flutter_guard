import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../shared/widgets.dart';

class EnvironmentPage extends StatelessWidget {
  const EnvironmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final live = FlutterGuardScope.of(context);
    final development = FlutterGuardConfig(
      environment: const EnvironmentConfig(
        environment: GuardEnvironment.development,
      ),
    );
    final production = FlutterGuardConfig(
      environment: const EnvironmentConfig(
        environment: GuardEnvironment.production,
      ),
    );
    return DemoScaffold(
      title: 'Environment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Current process',
            child: Text(
              'Environment: ${live.environment.name.toUpperCase()}\n'
              'Logging: ${live.config.diagnostics.logLevel.name.toUpperCase()}\n'
              'Inspector: ${live.inspectorEnabled ? 'ENABLED' : 'DISABLED'}',
            ),
          ),
          SectionCard(
            title: 'DEVELOPMENT preset',
            child: Text(
              'Environment: DEVELOPMENT\n'
              'Logging: ${development.diagnostics.logLevel.name.toUpperCase()}\n'
              'Inspector: ${development.inspector.enabled ? 'ENABLED' : 'DISABLED'}',
            ),
          ),
          SectionCard(
            title: 'PRODUCTION preset',
            child: Text(
              'Environment: PRODUCTION\n'
              'Logging: ${production.diagnostics.logLevel.name.toUpperCase()}\n'
              'Inspector: ${production.inspector.enabled ? 'ENABLED' : 'DISABLED'}',
            ),
          ),
        ],
      ),
    );
  }
}
