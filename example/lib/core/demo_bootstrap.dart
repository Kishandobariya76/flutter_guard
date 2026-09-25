import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import 'demo_session.dart';
import 'demo_transport.dart';

final demoTransport = DemoTransport(session: demoSession);

Future<FlutterGuard> bootstrapGuard({
  GuardEnvironment environment = GuardEnvironment.development,
}) {
  return FlutterGuard.initialize(
    FlutterGuardConfig(
      baseUrl: 'https://demo.flutterguard.local',
      transport: demoTransport,
      store: demoStore,
      connectivityAdapter: demoConnectivity,
      auth: AuthConfig(
        accessTokenProvider: demoSession.readAccess,
        refreshToken: demoSession.refresh,
      ),
      cache: const CacheConfig(
        enabled: true,
        defaultTtl: Duration(minutes: 2),
        persistent: true,
      ),
      offline: const OfflineConfig(
        enabled: true,
        persistentQueue: true,
        autoSync: true,
      ),
      featureFlags: FeatureFlagConfig(
        userId: 'demo-user',
        appVersion: '0.1.0',
        flags: <String, FeatureFlag>{
          'new_checkout': FeatureFlag.boolean(
            true,
            key: 'new_checkout',
            description: 'Example checkout flag',
          ),
          'banner_text': FeatureFlag.string('Welcome', key: 'banner_text'),
          'page_size': FeatureFlag.integer(20, key: 'page_size'),
          'animation_scale': FeatureFlag.number(1.0, key: 'animation_scale'),
          'theme_json': FeatureFlag.json(<String, Object?>{
            'density': 'comfortable',
          }, key: 'theme_json'),
        },
      ),
      environment: EnvironmentConfig(environment: environment),
    ),
  );
}
