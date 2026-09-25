/// Retry policy applied to idempotent requests, or to any request that opts in.
///
/// ```dart
/// RetryConfig(
///   maxAttempts: 3,
///   initialDelay: Duration(milliseconds: 500),
///   maxDelay: Duration(seconds: 10),
///   exponentialBackoff: true,
///   jitter: true,
/// )
/// ```
///
/// **Production note:** Keep [maxAttempts] small. High retry counts increase
/// server load and user-visible latency.
class RetryConfig {
  /// Creates a retry policy.
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.exponentialBackoff = true,
    this.jitter = true,
    this.retryableStatusCodes = defaultRetryableStatusCodes,
    this.retryNonIdempotent = false,
  });

  /// HTTP statuses retried by default.
  static const Set<int> defaultRetryableStatusCodes = <int>{
    408,
    429,
    500,
    502,
    503,
    504,
  };

  /// Maximum number of attempts, including the first try.
  ///
  /// **Type:** `int`
  /// **Required:** no
  /// **Default:** `3`
  /// **Purpose:** Caps how many times FlutterGuard will send the same request.
  /// **Allowed values:** `1` or greater. `1` disables retries.
  /// **Example:** `RetryConfig(maxAttempts: 3)`
  /// **Production recommendation:** `2` or `3`. Avoid values above `5`.
  /// **Common mistakes:** Setting this very high, which can amplify outages.
  final int maxAttempts;

  /// Delay before the second attempt when backoff is disabled, or the base
  /// delay when backoff is enabled.
  ///
  /// **Type:** `Duration`
  /// **Required:** no
  /// **Default:** `500ms`
  /// **Purpose:** Gives a failing server time to recover.
  /// **Allowed values:** Any non-negative duration.
  /// **Example:** `RetryConfig(initialDelay: Duration(milliseconds: 500))`
  /// **Production recommendation:** `250ms` to `1s`.
  /// **Common mistakes:** Using `Duration.zero` with many attempts, which
  /// creates a tight retry loop.
  final Duration initialDelay;

  /// Upper bound for computed backoff delays.
  ///
  /// **Type:** `Duration`
  /// **Required:** no
  /// **Default:** `10s`
  /// **Purpose:** Prevents exponential backoff from waiting too long.
  /// **Allowed values:** Greater than or equal to [initialDelay].
  /// **Example:** `RetryConfig(maxDelay: Duration(seconds: 10))`
  /// **Production recommendation:** `5s` to `30s`.
  /// **Common mistakes:** Setting this lower than [initialDelay].
  final Duration maxDelay;

  /// Whether each retry delay doubles, up to [maxDelay].
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Spreads retries during an outage.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `RetryConfig(exponentialBackoff: true)`
  /// **Production recommendation:** Keep enabled.
  /// **Common mistakes:** Disabling backoff while keeping a high attempt count.
  final bool exponentialBackoff;

  /// Whether a random component is added to each delay.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Prevents synchronized retry storms from many clients.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `RetryConfig(jitter: true)`
  /// **Production recommendation:** Keep enabled.
  /// **Common mistakes:** Disabling jitter in large client fleets.
  final bool jitter;

  /// HTTP statuses that may be retried.
  ///
  /// **Type:** `Set<int>`
  /// **Required:** no
  /// **Default:** `{408, 429, 500, 502, 503, 504}`
  /// **Purpose:** Restricts retries to transient failures.
  /// **Allowed values:** Valid HTTP status codes.
  /// **Example:** `RetryConfig(retryableStatusCodes: {503, 504})`
  /// **Production recommendation:** Do not include `4xx` other than `408` and
  /// `429`.
  /// **Common mistakes:** Adding `401` here. Token refresh handles `401`.
  final Set<int> retryableStatusCodes;

  /// Whether POST and PATCH may be retried.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `false`
  /// **Purpose:** Avoids duplicate writes when a timeout occurs after the
  /// server accepted the request.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `RetryConfig(retryNonIdempotent: false)`
  /// **Production recommendation:** Leave `false` unless the endpoint is
  /// idempotent.
  /// **Common mistakes:** Enabling this for order-creation endpoints.
  final bool retryNonIdempotent;

  /// Default policy used when the caller does not supply one.
  static const RetryConfig defaults = RetryConfig();
}
