import 'dart:collection';

import '../../core/config/diagnostics_config.dart';
import 'request_metric.dart';

/// Aggregated request counters and recent samples.
class GuardMetrics {
  /// Creates a metrics collector.
  GuardMetrics(this._config);

  final DiagnosticsConfig _config;
  final ListQueue<RequestMetric> _samples = ListQueue<RequestMetric>();

  /// Total finished requests.
  int totalRequests = 0;

  /// Requests that completed without a Guard exception.
  int successfulRequests = 0;

  /// Requests that threw or returned an error status.
  int failedRequests = 0;

  /// Cache reads that found an entry.
  int cacheHits = 0;

  /// Cache reads that missed.
  int cacheMisses = 0;

  /// Total retry attempts after the first try.
  int retryCount = 0;

  /// Requests slower than [DiagnosticsConfig.slowRequestThreshold].
  int slowRequests = 0;

  /// Current offline-queue depth, updated by the queue.
  int offlineQueuePending = 0;

  /// Recent samples, oldest first. Capped at [DiagnosticsConfig.maxLogEntries].
  List<RequestMetric> get samples => List<RequestMetric>.unmodifiable(_samples);

  /// Average end-to-end duration, or [Duration.zero] when there are no samples.
  Duration get averageDuration {
    if (_samples.isEmpty) {
      return Duration.zero;
    }
    final totalMs = _samples.fold<int>(
      0,
      (sum, sample) => sum + sample.duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ _samples.length);
  }

  /// Records one completed request.
  void record(RequestMetric sample) {
    if (!_config.enabled || !_config.collectMetrics) {
      return;
    }
    totalRequests += 1;
    if (sample.failed) {
      failedRequests += 1;
    } else {
      successfulRequests += 1;
    }
    retryCount += sample.retryCount;
    if (sample.fromCache) {
      cacheHits += 1;
    }
    if (sample.duration >= _config.slowRequestThreshold) {
      slowRequests += 1;
    }
    _samples.addLast(sample);
    while (_samples.length > _config.maxLogEntries) {
      _samples.removeFirst();
    }
  }

  /// Records a cache miss that did not produce a [RequestMetric].
  void recordCacheMiss() {
    if (!_config.enabled || !_config.collectMetrics) {
      return;
    }
    cacheMisses += 1;
  }

  /// Records a cache hit that did not already go through [record].
  void recordCacheHit() {
    if (!_config.enabled || !_config.collectMetrics) {
      return;
    }
    cacheHits += 1;
  }

  /// Clears counters and samples. Intended for debug builds.
  void reset() {
    totalRequests = 0;
    successfulRequests = 0;
    failedRequests = 0;
    cacheHits = 0;
    cacheMisses = 0;
    retryCount = 0;
    slowRequests = 0;
    offlineQueuePending = 0;
    _samples.clear();
  }
}
