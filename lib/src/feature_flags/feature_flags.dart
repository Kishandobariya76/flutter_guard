import 'package:flutter/foundation.dart';

import '../core/config/feature_flag_config.dart';
import '../core/environment/guard_environment.dart';
import 'feature_flag.dart';
import 'feature_flag_provider.dart';

/// Local feature-flag evaluator with rollout and targeting.
class FeatureFlags {
  /// Creates an evaluator.
  FeatureFlags({
    required FeatureFlagConfig config,
    required GuardEnvironment environment,
  }) : _config = config,
       _environment = environment,
       _provider = config.provider ?? LocalFeatureFlagProvider(config.flags),
       _userId = config.userId ?? 'anonymous',
       _appVersion = config.appVersion,
       _flags = Map<String, FeatureFlag>.of(config.flags);

  final FeatureFlagConfig _config;
  final GuardEnvironment _environment;
  final FeatureFlagProvider _provider;
  String _userId;
  String? _appVersion;
  final Map<String, FeatureFlag> _flags;

  /// Known flags.
  Map<String, FeatureFlag> get flags =>
      Map<String, FeatureFlag>.unmodifiable(_flags);

  /// Reloads flags from the provider.
  Future<void> reload() async {
    final loaded = await _provider.load();
    _flags
      ..clear()
      ..addAll(loaded);
  }

  /// Creates or replaces a flag in the local provider.
  Future<void> upsert(FeatureFlag flag) async {
    await _provider.upsert(flag);
    _flags[flag.key] = flag;
  }

  /// Removes a flag.
  Future<void> delete(String key) async {
    await _provider.delete(key);
    _flags.remove(key);
  }

  /// Updates the rollout identity.
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Updates the app version used for targeting.
  void setAppVersion(String version) {
    _appVersion = version;
  }

  /// Whether [key] is enabled after targeting and rollout.
  bool isEnabled(String key) {
    if (!_config.enabled) {
      return false;
    }
    final flag = _flags[key];
    if (flag == null || !flag.enabled) {
      return false;
    }
    if (flag.environments != null &&
        !flag.environments!.contains(_environment)) {
      return false;
    }
    if (flag.platforms != null &&
        !flag.platforms!
            .map((item) => item.toLowerCase())
            .contains(_platform())) {
      return false;
    }
    if (flag.minVersion != null &&
        _appVersion != null &&
        _compareVersions(_appVersion!, flag.minVersion!) < 0) {
      return false;
    }
    if (flag.rolloutPercentage >= 100) {
      return true;
    }
    if (flag.rolloutPercentage <= 0) {
      return false;
    }
    return _bucket(key, _userId) < flag.rolloutPercentage;
  }

  /// Boolean value, or [fallback] when the flag is missing or disabled.
  bool getBool(String key, {bool fallback = false}) {
    if (!isEnabled(key)) {
      return fallback;
    }
    final value = _flags[key]?.value;
    return value is bool ? value : fallback;
  }

  /// String value, or [fallback].
  String getString(String key, {String fallback = ''}) {
    if (!isEnabled(key)) {
      return fallback;
    }
    return _flags[key]?.value?.toString() ?? fallback;
  }

  /// Integer value, or [fallback].
  int getInt(String key, {int fallback = 0}) {
    if (!isEnabled(key)) {
      return fallback;
    }
    final value = _flags[key]?.value;
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  /// Double value, or [fallback].
  double getDouble(String key, {double fallback = 0}) {
    if (!isEnabled(key)) {
      return fallback;
    }
    final value = _flags[key]?.value;
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  /// JSON value, or [fallback].
  Object? getJson(String key, {Object? fallback}) {
    if (!isEnabled(key)) {
      return fallback;
    }
    return _flags[key]?.value ?? fallback;
  }

  String _platform() {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name.toLowerCase();
  }

  int _bucket(String key, String userId) {
    var hash = 0;
    for (final code in '$key:$userId'.codeUnits) {
      hash = 0x7fffffff & ((hash * 31) + code);
    }
    return hash % 100;
  }

  int _compareVersions(String current, String minimum) {
    List<int> parts(String value) {
      return value.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    }

    final a = parts(current);
    final b = parts(minimum);
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final left = i < a.length ? a[i] : 0;
      final right = i < b.length ? b[i] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }
    return 0;
  }
}
