import 'log_level.dart';

/// One structured log record retained for the inspector and log viewer.
class LogEvent {
  /// Creates a log event.
  const LogEvent({
    required this.level,
    required this.message,
    required this.timestamp,
    this.metadata = const <String, Object?>{},
    this.requestId,
  });

  /// Severity.
  final LogLevel level;

  /// Human-readable message. Must not contain secrets. Metadata is redacted
  /// before the event is stored.
  final String message;

  /// When the event was recorded.
  final DateTime timestamp;

  /// Structured fields, already redacted.
  final Map<String, Object?> metadata;

  /// Related request, when any.
  final String? requestId;
}
