/// Deployment environment used for presets and feature-flag targeting.
enum GuardEnvironment {
  /// Local and internal builds.
  ///
  /// Preset: debug logging, inspector enabled, diagnostics enabled.
  development,

  /// Pre-production builds shared with QA or stakeholders.
  ///
  /// Preset: info logging, inspector enabled, diagnostics enabled.
  staging,

  /// Customer-facing builds.
  ///
  /// Preset: error logging, inspector disabled, diagnostics enabled.
  production,
}
