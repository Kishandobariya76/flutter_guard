import '../environment/guard_environment.dart';

/// Environment name and whether presets should be applied.
class EnvironmentConfig {
  /// Creates environment settings.
  const EnvironmentConfig({
    this.environment = GuardEnvironment.development,
    this.applyPresets = true,
  });

  /// Current environment.
  ///
  /// **Type:** [GuardEnvironment]
  /// **Required:** no
  /// **Default:** [GuardEnvironment.development]
  /// **Purpose:** Selects presets and flag targeting.
  /// **Allowed values:** `development`, `staging`, `production`
  /// **Example:** `EnvironmentConfig(environment: GuardEnvironment.development)`
  /// **Production recommendation:** Set this from `--dart-define`, not by
  /// editing source for each build.
  /// **Common mistakes:** Shipping the development preset to the store.
  final GuardEnvironment environment;

  /// Whether FlutterGuard adjusts logging and inspector defaults.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Applies safe production defaults automatically.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `EnvironmentConfig(applyPresets: true)`
  /// **Production recommendation:** Keep enabled unless you set every option
  /// yourself.
  /// **Common mistakes:** Disabling presets and forgetting to disable the
  /// inspector.
  final bool applyPresets;

  /// Default environment settings.
  static const EnvironmentConfig defaults = EnvironmentConfig();
}
