import 'dart:collection';

import '../../core/config/diagnostics_config.dart';
import 'log_event.dart';
import 'log_level.dart';
import 'redaction.dart';

/// In-memory structured logger with redaction and inspector access.
class GuardLogger {
  /// Creates a logger.
  GuardLogger(DiagnosticsConfig config)
    : _config = config,
      _redactor = LogRedactor(
        enabled: config.redactSensitiveFields,
        extraKeys: config.extraRedactedKeys,
      );

  final DiagnosticsConfig _config;
  final LogRedactor _redactor;
  final ListQueue<LogEvent> _events = ListQueue<LogEvent>();

  /// Redactor used by the network pipeline and inspector.
  LogRedactor get redactor => _redactor;

  /// Snapshot of retained events, oldest first.
  List<LogEvent> get events => List<LogEvent>.unmodifiable(_events);

  /// Records a debug event.
  void debug(
    String message, {
    Map<String, Object?> metadata = const {},
    String? requestId,
  }) {
    log(LogLevel.debug, message, metadata: metadata, requestId: requestId);
  }

  /// Records an info event.
  void info(
    String message, {
    Map<String, Object?> metadata = const {},
    String? requestId,
  }) {
    log(LogLevel.info, message, metadata: metadata, requestId: requestId);
  }

  /// Records a warning.
  void warning(
    String message, {
    Map<String, Object?> metadata = const {},
    String? requestId,
  }) {
    log(LogLevel.warning, message, metadata: metadata, requestId: requestId);
  }

  /// Records an error.
  void error(
    String message, {
    Map<String, Object?> metadata = const {},
    String? requestId,
  }) {
    log(LogLevel.error, message, metadata: metadata, requestId: requestId);
  }

  /// Records a critical event.
  void critical(
    String message, {
    Map<String, Object?> metadata = const {},
    String? requestId,
  }) {
    log(LogLevel.critical, message, metadata: metadata, requestId: requestId);
  }

  /// Records an event at [level] when diagnostics are enabled.
  void log(
    LogLevel level,
    String message, {
    Map<String, Object?> metadata = const {},
    String? requestId,
  }) {
    if (!_config.enabled || !level.isAtLeast(_config.logLevel)) {
      return;
    }
    final event = LogEvent(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      metadata: _redactor.redactMap(metadata),
      requestId: requestId,
    );
    _events.addLast(event);
    while (_events.length > _config.maxLogEntries) {
      _events.removeFirst();
    }
  }

  /// Events whose level is at least [minimum] and whose message or metadata
  /// contains [query], case-insensitively.
  List<LogEvent> filter({LogLevel? minimum, String? query}) {
    final needle = query?.toLowerCase();
    return _events.where((event) {
      if (minimum != null && !event.level.isAtLeast(minimum)) {
        return false;
      }
      if (needle == null || needle.isEmpty) {
        return true;
      }
      if (event.message.toLowerCase().contains(needle)) {
        return true;
      }
      return event.metadata.values.any(
        (value) => value.toString().toLowerCase().contains(needle),
      );
    }).toList();
  }

  /// Clears retained events. Intended for debug builds.
  void clear() {
    _events.clear();
  }
}
