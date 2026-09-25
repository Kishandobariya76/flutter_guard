import '../core/environment/guard_environment.dart';

/// Supported local feature-flag value kinds.
enum FeatureFlagType {
  /// `true` or `false`.
  boolean,

  /// Arbitrary text.
  string,

  /// 64-bit integer.
  integer,

  /// Floating-point number.
  doubleValue,

  /// JSON object or array.
  json,
}

/// A locally evaluated feature flag.
class FeatureFlag {
  /// Creates a flag.
  const FeatureFlag({
    required this.key,
    required this.type,
    required this.value,
    this.enabled = true,
    this.rolloutPercentage = 100,
    this.platforms,
    this.minVersion,
    this.environments,
    this.description,
  });

  /// Boolean flag.
  factory FeatureFlag.boolean(
    bool value, {
    String key = '',
    bool enabled = true,
    double rolloutPercentage = 100,
    List<String>? platforms,
    String? minVersion,
    List<GuardEnvironment>? environments,
    String? description,
  }) {
    return FeatureFlag(
      key: key,
      type: FeatureFlagType.boolean,
      value: value,
      enabled: enabled,
      rolloutPercentage: rolloutPercentage,
      platforms: platforms,
      minVersion: minVersion,
      environments: environments,
      description: description,
    );
  }

  /// String flag.
  factory FeatureFlag.string(
    String value, {
    String key = '',
    bool enabled = true,
    double rolloutPercentage = 100,
    List<String>? platforms,
    String? minVersion,
    List<GuardEnvironment>? environments,
    String? description,
  }) {
    return FeatureFlag(
      key: key,
      type: FeatureFlagType.string,
      value: value,
      enabled: enabled,
      rolloutPercentage: rolloutPercentage,
      platforms: platforms,
      minVersion: minVersion,
      environments: environments,
      description: description,
    );
  }

  /// Integer flag.
  factory FeatureFlag.integer(
    int value, {
    String key = '',
    bool enabled = true,
    double rolloutPercentage = 100,
    List<String>? platforms,
    String? minVersion,
    List<GuardEnvironment>? environments,
    String? description,
  }) {
    return FeatureFlag(
      key: key,
      type: FeatureFlagType.integer,
      value: value,
      enabled: enabled,
      rolloutPercentage: rolloutPercentage,
      platforms: platforms,
      minVersion: minVersion,
      environments: environments,
      description: description,
    );
  }

  /// Double flag.
  factory FeatureFlag.number(
    double value, {
    String key = '',
    bool enabled = true,
    double rolloutPercentage = 100,
    List<String>? platforms,
    String? minVersion,
    List<GuardEnvironment>? environments,
    String? description,
  }) {
    return FeatureFlag(
      key: key,
      type: FeatureFlagType.doubleValue,
      value: value,
      enabled: enabled,
      rolloutPercentage: rolloutPercentage,
      platforms: platforms,
      minVersion: minVersion,
      environments: environments,
      description: description,
    );
  }

  /// JSON flag. [value] must be JSON-encodable.
  factory FeatureFlag.json(
    Object? value, {
    String key = '',
    bool enabled = true,
    double rolloutPercentage = 100,
    List<String>? platforms,
    String? minVersion,
    List<GuardEnvironment>? environments,
    String? description,
  }) {
    return FeatureFlag(
      key: key,
      type: FeatureFlagType.json,
      value: value,
      enabled: enabled,
      rolloutPercentage: rolloutPercentage,
      platforms: platforms,
      minVersion: minVersion,
      environments: environments,
      description: description,
    );
  }

  /// Unique flag key.
  final String key;

  /// Runtime type of [value].
  final FeatureFlagType type;

  /// Raw value.
  final Object? value;

  /// Master switch evaluated before targeting.
  final bool enabled;

  /// Percentage of users who receive the flag, from `0` to `100`.
  final double rolloutPercentage;

  /// Allowed platforms such as `android`, `ios`, `web`. `null` means all.
  final List<String>? platforms;

  /// Minimum semantic app version. `null` means any version.
  final String? minVersion;

  /// Environments that may receive the flag. `null` means all.
  final List<GuardEnvironment>? environments;

  /// Optional documentation shown in the inspector.
  final String? description;

  /// Returns a copy with selected fields replaced.
  FeatureFlag copyWith({
    String? key,
    FeatureFlagType? type,
    Object? value,
    bool? enabled,
    double? rolloutPercentage,
    List<String>? platforms,
    String? minVersion,
    List<GuardEnvironment>? environments,
    String? description,
  }) {
    return FeatureFlag(
      key: key ?? this.key,
      type: type ?? this.type,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      rolloutPercentage: rolloutPercentage ?? this.rolloutPercentage,
      platforms: platforms ?? this.platforms,
      minVersion: minVersion ?? this.minVersion,
      environments: environments ?? this.environments,
      description: description ?? this.description,
    );
  }
}
