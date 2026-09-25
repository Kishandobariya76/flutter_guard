import '../core/config/diagnostics_config.dart';
import 'logging/guard_logger.dart';
import 'metrics/guard_metrics.dart';

/// Combined diagnostics facade exposed on [FlutterGuard.diagnostics].
class GuardDiagnostics {
  /// Creates a diagnostics facade.
  GuardDiagnostics({
    required DiagnosticsConfig config,
    required this.logger,
    required this.metrics,
  }) : _config = config;

  final DiagnosticsConfig _config;

  /// Structured logger.
  final GuardLogger logger;

  /// Request counters and samples.
  final GuardMetrics metrics;

  /// Whether collection is enabled.
  bool get enabled => _config.enabled;

  /// Clears logs and metrics. Intended for debug builds.
  void reset() {
    logger.clear();
    metrics.reset();
  }
}
