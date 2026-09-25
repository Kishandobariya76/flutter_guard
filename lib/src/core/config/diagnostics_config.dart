import '../../diagnostics/logging/log_level.dart';

/// Logging, metrics, and redaction settings.
class DiagnosticsConfig {
  /// Creates diagnostics settings.
  const DiagnosticsConfig({
    this.enabled = true,
    this.logLevel = LogLevel.info,
    this.maxLogEntries = 500,
    this.redactSensitiveFields = true,
    this.extraRedactedKeys = const <String>[],
    this.collectMetrics = true,
    this.slowRequestThreshold = const Duration(milliseconds: 1000),
  });

  /// Whether diagnostics collection is active.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Records logs, metrics, and inspector snapshots.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `DiagnosticsConfig(enabled: true)`
  /// **Production recommendation:** Keep enabled. Cost is bounded by the ring
  /// buffer.
  /// **Common mistakes:** Disabling this and then expecting the inspector to
  /// show request history.
  final bool enabled;

  /// Minimum severity written to the logger.
  ///
  /// **Type:** [LogLevel]
  /// **Required:** no
  /// **Default:** [LogLevel.info], or [LogLevel.debug] in development when
  /// environment presets are applied.
  /// **Purpose:** Filters noise.
  /// **Allowed values:** Any [LogLevel].
  /// **Example:** `DiagnosticsConfig(logLevel: LogLevel.info)`
  /// **Production recommendation:** [LogLevel.error] or [LogLevel.warning].
  /// **Common mistakes:** Shipping [LogLevel.debug] to production.
  final LogLevel logLevel;

  /// Maximum in-memory log events retained for the inspector.
  ///
  /// **Type:** `int`
  /// **Required:** no
  /// **Default:** `500`
  /// **Purpose:** Bounds memory used by the log viewer.
  /// **Allowed values:** `1` or greater.
  /// **Example:** `DiagnosticsConfig(maxLogEntries: 500)`
  /// **Production recommendation:** `200` to `1000`.
  /// **Common mistakes:** Using an unbounded list of log events.
  final int maxLogEntries;

  /// Whether known secret field names are replaced before logging.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Prevents tokens and passwords from appearing in logs.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `DiagnosticsConfig(redactSensitiveFields: true)`
  /// **Production recommendation:** Always leave enabled.
  /// **Common mistakes:** Disabling this to "debug auth" and committing the
  /// change.
  final bool redactSensitiveFields;

  /// Additional keys treated as sensitive, matched case-insensitively.
  ///
  /// **Type:** `List<String>`
  /// **Required:** no
  /// **Default:** empty
  /// **Purpose:** Extends the built-in redaction list.
  /// **Allowed values:** Header or map keys.
  /// **Example:** `DiagnosticsConfig(extraRedactedKeys: ['sessionId'])`
  /// **Production recommendation:** Add any custom auth header you use.
  /// **Common mistakes:** Adding `id` and redacting harmless identifiers.
  final List<String> extraRedactedKeys;

  /// Whether request timing and counters are recorded.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Feeds the diagnostics dashboard and inspector.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `DiagnosticsConfig(collectMetrics: true)`
  /// **Production recommendation:** Keep enabled.
  /// **Common mistakes:** Expecting unsupported metrics such as radio quality.
  final bool collectMetrics;

  /// Duration at which a completed request is counted as slow.
  ///
  /// **Type:** `Duration`
  /// **Required:** no
  /// **Default:** `1000ms`
  /// **Purpose:** Highlights outliers in the inspector.
  /// **Allowed values:** Any positive duration.
  /// **Example:** `DiagnosticsConfig(slowRequestThreshold: Duration(seconds: 1))`
  /// **Production recommendation:** Set from your p95 latency budget.
  /// **Common mistakes:** Using a threshold so low that every request is slow.
  final Duration slowRequestThreshold;

  /// Default diagnostics settings.
  static const DiagnosticsConfig defaults = DiagnosticsConfig();
}
