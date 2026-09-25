/// Debug inspector settings.
class InspectorConfig {
  /// Creates inspector settings.
  const InspectorConfig({this.enabled = true, this.allowInRelease = false});

  /// Whether [GuardInspector.show] may present UI.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`, or `false` in production when presets are applied.
  /// **Purpose:** Gates the in-app inspector.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `InspectorConfig(enabled: true)`
  /// **Production recommendation:** Disable in production builds.
  /// **Common mistakes:** Leaving it enabled in a store build.
  final bool enabled;

  /// Whether the inspector can open when `kReleaseMode` is true.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `false`
  /// **Purpose:** Extra safety latch for release binaries.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `InspectorConfig(allowInRelease: false)`
  /// **Production recommendation:** Keep `false`.
  /// **Common mistakes:** Enabling this to debug a production user session
  /// that may contain personal data.
  final bool allowInRelease;

  /// Default inspector settings.
  static const InspectorConfig defaults = InspectorConfig();
}
