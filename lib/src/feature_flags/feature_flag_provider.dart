import 'feature_flag.dart';

/// Source of feature flags. V1 ships a local provider. Remote sources implement
/// this interface in a future package.
abstract class FeatureFlagProvider {
  /// All known flags.
  Future<Map<String, FeatureFlag>> load();

  /// Writes or replaces a flag.
  Future<void> upsert(FeatureFlag flag);

  /// Removes a flag.
  Future<void> delete(String key);
}

/// In-memory flag source used by default.
class LocalFeatureFlagProvider implements FeatureFlagProvider {
  /// Creates a local provider.
  LocalFeatureFlagProvider([Map<String, FeatureFlag>? seed])
    : _flags = Map<String, FeatureFlag>.of(
        seed ?? const <String, FeatureFlag>{},
      );

  final Map<String, FeatureFlag> _flags;

  @override
  Future<Map<String, FeatureFlag>> load() async {
    return Map<String, FeatureFlag>.of(_flags);
  }

  @override
  Future<void> upsert(FeatureFlag flag) async {
    _flags[flag.key] = flag;
  }

  @override
  Future<void> delete(String key) async {
    _flags.remove(key);
  }
}
