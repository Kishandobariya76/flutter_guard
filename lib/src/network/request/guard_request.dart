import '../cache_policy.dart';
import '../cancellation/cancellation_token.dart';
import 'guard_multipart.dart';

/// Immutable request that flows through interceptors and the transport.
class GuardRequest {
  /// Creates a request.
  const GuardRequest({
    required this.method,
    required this.url,
    required this.requestId,
    this.path = '',
    this.query = const <String, String>{},
    this.headers = const <String, String>{},
    this.data,
    this.multipart,
    this.timeout,
    this.cancelToken,
    this.deduplicate = false,
    this.cachePolicy,
    this.cacheTags = const <String>[],
    this.cacheTtl,
    this.retry,
    this.queueIfOffline = false,
    this.priority,
    this.refreshAttempts = 0,
    this.rawBody = false,
  });

  /// HTTP method, upper-case.
  final String method;

  /// Absolute URL after [baseUrl] resolution.
  final Uri url;

  /// Original path supplied by the caller.
  final String path;

  /// Query parameters already encoded onto [url] and retained for cache keys.
  final Map<String, String> query;

  /// Request headers.
  final Map<String, String> headers;

  /// JSON-encodable body, or a raw `String` / `List<int>`.
  final Object? data;

  /// Multipart payload, when set.
  final GuardMultipart? multipart;

  /// Per-request timeout override.
  final Duration? timeout;

  /// Optional cancellation token.
  final CancellationToken? cancelToken;

  /// Whether this request may join an in-flight identical call.
  final bool deduplicate;

  /// Cache policy override.
  final CachePolicy? cachePolicy;

  /// Tags written with a successful cache entry.
  final List<String> cacheTags;

  /// TTL override for a successful cache write.
  final Duration? cacheTtl;

  /// When `true`, retries are allowed even for POST/PATCH. When `false`,
  /// retries are disabled. When `null`, [RetryConfig] decides.
  final bool? retry;

  /// Whether this request may enter the offline queue.
  final bool queueIfOffline;

  /// Offline-queue priority override.
  final int? priority;

  /// How many times this request has already triggered token refresh.
  final int refreshAttempts;

  /// Unique id assigned before interceptors run.
  final String requestId;

  /// When true, the body is passed to the parser as bytes, not JSON.
  final bool rawBody;

  /// Whether the method is considered idempotent for retries.
  bool get isIdempotent {
    return method == 'GET' ||
        method == 'HEAD' ||
        method == 'PUT' ||
        method == 'DELETE' ||
        method == 'OPTIONS';
  }

  /// Whether the request is a write that may be queued while offline.
  bool get isMutation {
    return method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
  }

  /// Returns a copy with selected fields replaced.
  GuardRequest copyWith({
    String? method,
    Uri? url,
    String? path,
    Map<String, String>? query,
    Map<String, String>? headers,
    Object? data,
    GuardMultipart? multipart,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    CachePolicy? cachePolicy,
    List<String>? cacheTags,
    Duration? cacheTtl,
    bool? retry,
    bool? queueIfOffline,
    int? priority,
    int? refreshAttempts,
    String? requestId,
    bool? rawBody,
  }) {
    return GuardRequest(
      method: method ?? this.method,
      url: url ?? this.url,
      path: path ?? this.path,
      query: query ?? this.query,
      headers: headers ?? this.headers,
      data: data ?? this.data,
      multipart: multipart ?? this.multipart,
      timeout: timeout ?? this.timeout,
      cancelToken: cancelToken ?? this.cancelToken,
      deduplicate: deduplicate ?? this.deduplicate,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      cacheTags: cacheTags ?? this.cacheTags,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      retry: retry ?? this.retry,
      queueIfOffline: queueIfOffline ?? this.queueIfOffline,
      priority: priority ?? this.priority,
      refreshAttempts: refreshAttempts ?? this.refreshAttempts,
      requestId: requestId ?? this.requestId,
      rawBody: rawBody ?? this.rawBody,
    );
  }
}
