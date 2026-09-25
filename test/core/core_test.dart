import 'package:flutter_guard/flutter_guard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scripted_transport.dart';

void main() {
  tearDown(() async {
    await FlutterGuard.reset();
  });

  test('initialize registers the singleton', () async {
    final transport = ScriptedTransport();
    final guard = await FlutterGuard.initialize(
      FlutterGuardConfig(
        baseUrl: 'https://api.example.com',
        transport: transport,
        environment: const EnvironmentConfig(applyPresets: false),
      ),
    );
    expect(FlutterGuard.isInitialized, isTrue);
    expect(identical(FlutterGuard.instance, guard), isTrue);
    expect(guard.environment, GuardEnvironment.development);
  });

  test('production presets disable the inspector and raise the log level', () {
    final config = FlutterGuardConfig(
      environment: const EnvironmentConfig(
        environment: GuardEnvironment.production,
      ),
    );
    expect(config.inspector.enabled, isFalse);
    expect(config.diagnostics.logLevel, LogLevel.error);
  });

  test('development presets enable debug logging', () {
    final config = FlutterGuardConfig();
    expect(config.inspector.enabled, isTrue);
    expect(config.diagnostics.logLevel, LogLevel.debug);
  });

  test('Result.when maps success and failure', () {
    const success = Result<int>.success(4);
    const failure = Result<int>.failure(UnknownException('nope'));
    expect(success.when(success: (value) => value, failure: (_) => 0), 4);
    expect(
      failure.when(success: (_) => '', failure: (error) => error.message),
      'nope',
    );
  });

  test('config catalog covers every public owner', () {
    final owners = ConfigCatalog.options.map((item) => item.owner).toSet();
    expect(
      owners,
      containsAll(<String>[
        'FlutterGuardConfig',
        'NetworkConfig',
        'RetryConfig',
        'AuthConfig',
        'CacheConfig',
        'OfflineConfig',
        'DiagnosticsConfig',
        'InspectorConfig',
        'FeatureFlagConfig',
        'EnvironmentConfig',
      ]),
    );
    expect(ConfigCatalog.options.length, greaterThanOrEqualTo(60));
  });

  test('create does not replace the singleton', () async {
    final first = await FlutterGuard.initialize(
      FlutterGuardConfig(
        baseUrl: 'https://api.example.com',
        transport: ScriptedTransport(),
        environment: const EnvironmentConfig(applyPresets: false),
      ),
    );
    final second = await FlutterGuard.create(
      FlutterGuardConfig(
        baseUrl: 'https://other.example.com',
        transport: ScriptedTransport(),
        environment: const EnvironmentConfig(applyPresets: false),
      ),
    );
    expect(identical(FlutterGuard.instance, first), isTrue);
    expect(identical(second, first), isFalse);
    await second.dispose();
  });
}
