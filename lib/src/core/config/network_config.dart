import 'retry_config.dart';

/// HTTP client settings applied to every request unless overridden.
class NetworkConfig {
  /// Creates network settings.
  const NetworkConfig({
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.retry = const RetryConfig(),
    this.defaultHeaders = const <String, String>{},
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.enableDefaultDeduplication = false,
    this.userAgent = 'flutter_guard/0.1.0',
  });

  /// Time allowed to establish a connection.
  ///
  /// **Type:** `Duration`
  /// **Required:** no
  /// **Default:** `15s`
  /// **Purpose:** Fails fast when the host is unreachable.
  /// **Allowed values:** Any positive duration.
  /// **Example:** `NetworkConfig(connectTimeout: Duration(seconds: 15))`
  /// **Production recommendation:** `10s` to `20s`.
  /// **Common mistakes:** Using a multi-minute timeout that freezes the UI.
  final Duration connectTimeout;

  /// Time allowed to receive the response body after the connection is open.
  ///
  /// **Type:** `Duration`
  /// **Required:** no
  /// **Default:** `30s`
  /// **Purpose:** Bounds how long a slow endpoint can block a caller.
  /// **Allowed values:** Any positive duration.
  /// **Example:** `NetworkConfig(receiveTimeout: Duration(seconds: 30))`
  /// **Production recommendation:** Match the slowest legitimate API you call.
  /// **Common mistakes:** Setting this lower than large file downloads need.
  final Duration receiveTimeout;

  /// Time allowed to send the request body.
  ///
  /// **Type:** `Duration`
  /// **Required:** no
  /// **Default:** `30s`
  /// **Purpose:** Bounds large uploads on a poor connection.
  /// **Allowed values:** Any positive duration.
  /// **Example:** `NetworkConfig(sendTimeout: Duration(seconds: 30))`
  /// **Production recommendation:** Increase for multipart uploads.
  /// **Common mistakes:** Leaving this low for video or log uploads.
  final Duration sendTimeout;

  /// Default retry policy.
  ///
  /// **Type:** [RetryConfig]
  /// **Required:** no
  /// **Default:** [RetryConfig.defaults]
  /// **Purpose:** Applies retries without per-request configuration.
  /// **Allowed values:** Any [RetryConfig].
  /// **Example:** `NetworkConfig(retry: RetryConfig(maxAttempts: 3))`
  /// **Production recommendation:** Keep jitter and backoff enabled.
  /// **Common mistakes:** Copying development retry counts into production.
  final RetryConfig retry;

  /// Headers attached to every request.
  ///
  /// **Type:** `Map<String, String>`
  /// **Required:** no
  /// **Default:** empty
  /// **Purpose:** Shared headers such as `Accept` or a client identifier.
  /// **Allowed values:** Valid HTTP header names and values.
  /// **Example:** `NetworkConfig(defaultHeaders: {'Accept': 'application/json'})`
  /// **Production recommendation:** Do not put secrets here.
  /// **Common mistakes:** Adding `Authorization` here instead of [AuthConfig].
  final Map<String, String> defaultHeaders;

  /// Whether the transport should follow HTTP redirects.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Matches typical REST client behavior.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `NetworkConfig(followRedirects: true)`
  /// **Production recommendation:** Keep enabled unless you must inspect `3xx`.
  /// **Common mistakes:** Disabling this and treating `302` as an error.
  final bool followRedirects;

  /// Maximum number of redirects when [followRedirects] is true.
  ///
  /// **Type:** `int`
  /// **Required:** no
  /// **Default:** `5`
  /// **Purpose:** Prevents redirect loops.
  /// **Allowed values:** `0` or greater.
  /// **Example:** `NetworkConfig(maxRedirects: 5)`
  /// **Production recommendation:** `5`.
  /// **Common mistakes:** Setting this to `0` while leaving follow enabled.
  final int maxRedirects;

  /// Whether identical in-flight requests are shared by default.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `false`
  /// **Purpose:** Optional global deduplication. Per-request `deduplicate`
  /// overrides this value.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `NetworkConfig(enableDefaultDeduplication: false)`
  /// **Production recommendation:** Prefer per-request opt-in.
  /// **Common mistakes:** Enabling this globally for POST requests.
  final bool enableDefaultDeduplication;

  /// Value sent as the `User-Agent` header when the caller does not set one.
  ///
  /// **Type:** `String`
  /// **Required:** no
  /// **Default:** `flutter_guard/0.1.0`
  /// **Purpose:** Identifies the client to your API and logs.
  /// **Allowed values:** Any HTTP token-safe string.
  /// **Example:** `NetworkConfig(userAgent: 'my_app/1.4.0')`
  /// **Production recommendation:** Use your app name and version.
  /// **Common mistakes:** Putting device identifiers that become a privacy leak.
  final String userAgent;

  /// Default network settings.
  static const NetworkConfig defaults = NetworkConfig();
}
