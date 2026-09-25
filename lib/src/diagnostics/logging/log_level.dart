/// Severity of a structured log event.
enum LogLevel {
  /// Verbose diagnostic detail for local development.
  debug,

  /// Routine operational events.
  info,

  /// Recoverable problems that should be investigated.
  warning,

  /// Failed operations that the app handled.
  error,

  /// Failures that threaten the process or session.
  critical,
}

/// Ordering helpers for [LogLevel].
extension LogLevelSeverity on LogLevel {
  /// Numeric rank used for filtering. Higher is more severe.
  int get severity {
    return switch (this) {
      LogLevel.debug => 0,
      LogLevel.info => 1,
      LogLevel.warning => 2,
      LogLevel.error => 3,
      LogLevel.critical => 4,
    };
  }

  /// Whether this level should be recorded when [minimum] is the threshold.
  bool isAtLeast(LogLevel minimum) => severity >= minimum.severity;
}
