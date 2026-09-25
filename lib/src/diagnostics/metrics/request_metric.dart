/// Timing sample recorded for one completed request.
class RequestMetric {
  /// Creates a metric sample.
  const RequestMetric({
    required this.requestId,
    required this.method,
    required this.url,
    required this.statusCode,
    required this.duration,
    required this.timestamp,
    this.retryCount = 0,
    this.retryDuration,
    this.cacheDuration,
    this.queueDuration,
    this.responseSize,
    this.fromCache = false,
    this.failed = false,
  });

  /// Request identifier.
  final String requestId;

  /// HTTP method.
  final String method;

  /// Request URL.
  final String url;

  /// HTTP status or `0` when the transport failed.
  final int statusCode;

  /// End-to-end duration.
  final Duration duration;

  /// When the sample was recorded.
  final DateTime timestamp;

  /// Retries after the first attempt.
  final int retryCount;

  /// Time spent waiting between retries, when any.
  final Duration? retryDuration;

  /// Time spent in cache lookup, when measured.
  final Duration? cacheDuration;

  /// Time spent in the offline queue, when any.
  final Duration? queueDuration;

  /// Response body size in bytes, when known.
  final int? responseSize;

  /// Whether the response was served from cache.
  final bool fromCache;

  /// Whether the request ended in failure.
  final bool failed;
}
