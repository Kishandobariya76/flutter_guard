/// Typed HTTP result returned by [GuardNetwork].
///
/// ```dart
/// final response = await guard.network.get<User>(
///   '/users/123',
///   parser: User.fromJson,
/// );
/// print(response.statusCode);
/// print(response.fromCache);
/// print(response.duration);
/// ```
class ApiResponse<T> {
  /// Creates a response.
  const ApiResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.requestId,
    required this.duration,
    required this.timestamp,
    this.fromCache = false,
    this.isStale = false,
    this.retryCount = 0,
    this.url,
    this.method,
    this.responseSize,
  });

  /// Parsed body. `null` for empty bodies or HEAD requests.
  final T? data;

  /// HTTP status code. Cached responses reuse the stored status.
  final int statusCode;

  /// Response headers.
  final Map<String, String> headers;

  /// Identifier assigned when the request entered the pipeline.
  final String requestId;

  /// End-to-end duration including retries and refresh waits.
  final Duration duration;

  /// Whether [data] was served from cache.
  final bool fromCache;

  /// Whether a cached value was returned while a refresh is in flight.
  final bool isStale;

  /// Number of retries after the first attempt.
  final int retryCount;

  /// When the response was produced.
  final DateTime timestamp;

  /// Final URL, when known.
  final Uri? url;

  /// HTTP method, when known.
  final String? method;

  /// Body size in bytes, when the transport provided one.
  final int? responseSize;

  /// Returns a typed copy with a new [data] value.
  ApiResponse<R> map<R>(R? Function(T? data) transform) {
    return ApiResponse<R>(
      data: transform(data),
      statusCode: statusCode,
      headers: headers,
      requestId: requestId,
      duration: duration,
      timestamp: timestamp,
      fromCache: fromCache,
      isStale: isStale,
      retryCount: retryCount,
      url: url,
      method: method,
      responseSize: responseSize,
    );
  }

  /// Returns a copy with selected fields replaced.
  ApiResponse<T> copyWith({
    T? data,
    int? statusCode,
    Map<String, String>? headers,
    String? requestId,
    Duration? duration,
    DateTime? timestamp,
    bool? fromCache,
    bool? isStale,
    int? retryCount,
    Uri? url,
    String? method,
    int? responseSize,
  }) {
    return ApiResponse<T>(
      data: data ?? this.data,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      requestId: requestId ?? this.requestId,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      fromCache: fromCache ?? this.fromCache,
      isStale: isStale ?? this.isStale,
      retryCount: retryCount ?? this.retryCount,
      url: url ?? this.url,
      method: method ?? this.method,
      responseSize: responseSize ?? this.responseSize,
    );
  }
}
