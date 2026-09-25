import '../../feature_flags/feature_flag.dart';
import '../../feature_flags/feature_flag_provider.dart';

/// Local feature-flag settings.
class FeatureFlagConfig {
  /// Creates feature-flag settings.
  const FeatureFlagConfig({
    this.enabled = true,
    this.flags = const <String, FeatureFlag>{},
    this.userId,
    this.appVersion,
    this.provider,
  });

  /// Whether flag evaluation is active.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Allows a global kill switch for flag evaluation.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `FeatureFlagConfig(enabled: true)`
  /// **Production recommendation:** Keep enabled.
  /// **Common mistakes:** Treating a disabled evaluator as "all flags off"
  /// without documenting that `isEnabled` returns `false`.
  final bool enabled;

  /// Seed flags for the local provider.
  ///
  /// **Type:** `Map<String, FeatureFlag>`
  /// **Required:** no
  /// **Default:** empty
  /// **Purpose:** Ships compile-time defaults.
  /// **Allowed values:** Any map of flag keys to [FeatureFlag] values.
  /// **Example:** `FeatureFlagConfig(flags: {'new_checkout': FeatureFlag.boolean(true)})`
  /// **Production recommendation:** Keep defaults conservative.
  /// **Common mistakes:** Putting remote secrets in local flags.
  final Map<String, FeatureFlag> flags;

  /// Stable identifier used for percentage rollouts.
  ///
  /// **Type:** `String?`
  /// **Required:** no
  /// **Default:** `null` (a per-process anonymous id is used)
  /// **Purpose:** Makes rollout assignment deterministic per user.
  /// **Allowed values:** Any stable user or device id.
  /// **Example:** `FeatureFlagConfig(userId: currentUser.id)`
  /// **Production recommendation:** Use your account id, not an email.
  /// **Common mistakes:** Using a random id on every launch, which rerolls users.
  final String? userId;

  /// Semantic app version used for `minVersion` targeting.
  ///
  /// **Type:** `String?`
  /// **Required:** no
  /// **Default:** `null` (version targeting is skipped)
  /// **Purpose:** Enables flags only on new enough builds.
  /// **Allowed values:** `major.minor.patch` strings such as `1.4.0`.
  /// **Example:** `FeatureFlagConfig(appVersion: '1.4.0')`
  /// **Production recommendation:** Pass your real package version.
  /// **Common mistakes:** Passing a build number that is not comparable.
  final String? appVersion;

  /// Optional remote or custom provider.
  ///
  /// **Type:** [FeatureFlagProvider]?
  /// **Required:** no
  /// **Default:** local in-memory provider
  /// **Purpose:** Extension point for a future remote source.
  /// **Allowed values:** Any [FeatureFlagProvider].
  /// **Example:** `FeatureFlagConfig(provider: LocalFeatureFlagProvider())`
  /// **Production recommendation:** Use the local provider until a remote
  /// adapter exists.
  /// **Common mistakes:** Assuming a network fetch happens in V1. It does not.
  final FeatureFlagProvider? provider;

  /// Default feature-flag settings.
  static const FeatureFlagConfig defaults = FeatureFlagConfig();
}
