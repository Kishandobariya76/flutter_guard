import 'dart:async';
import 'dart:convert';

import '../../auth/guard_auth.dart';
import '../../cache/cache_entry.dart';
import '../../cache/guard_cache.dart';
import '../../connectivity/connectivity_monitor.dart';
import '../../core/config/flutter_guard_config.dart';
import '../../core/exceptions/exceptions.dart';
import '../../core/result/result.dart';
import '../../diagnostics/logging/guard_logger.dart';
import '../../diagnostics/metrics/guard_metrics.dart';
import '../../diagnostics/metrics/request_metric.dart';
import '../../offline/guard_offline.dart';
import '../../utils/request_id.dart';
import '../cache_policy.dart';
import '../cancellation/cancellation_token.dart';
import '../deduplication/request_deduplicator.dart';
import '../interceptor/guard_interceptor.dart';
import '../request/guard_multipart.dart';
import '../request/guard_request.dart';
import '../response/api_response.dart';
import '../response/guard_raw_response.dart';
import '../retry/retry_engine.dart';
import '../transport/guard_transport.dart';

/// Production HTTP client with retry, cache, auth, and offline integration.
class GuardNetwork {
  /// Creates a network client.
  GuardNetwork({
    required FlutterGuardConfig config,
    required GuardTransport transport,
    required GuardAuth auth,
    required GuardCache cache,
    required GuardOffline offline,
    required ConnectivityMonitor connectivity,
    required GuardLogger logger,
    required GuardMetrics metrics,
    List<GuardInterceptor>? interceptors,
  }) : _config = config,
       _transport = transport,
       _auth = auth,
       _cache = cache,
       _offline = offline,
       _connectivity = connectivity,
       _logger = logger,
       _metrics = metrics,
       _retry = RetryEngine(config.network.retry),
       _interceptors = List<GuardInterceptor>.of(
         interceptors ?? const <GuardInterceptor>[],
       );

  final FlutterGuardConfig _config;
  final GuardTransport _transport;
  final GuardAuth _auth;
  final GuardCache _cache;
  final GuardOffline _offline;
  final ConnectivityMonitor _connectivity;
  final GuardLogger _logger;
  final GuardMetrics _metrics;
  final RetryEngine _retry;
  final RequestDeduplicator _deduplicator = RequestDeduplicator();
  final List<GuardInterceptor> _interceptors;

  int _transportCalls = 0;

  /// Transport invocations since the last [resetCounters].
  int get transportCalls => _transportCalls;

  /// Callers that joined an in-flight deduplicated request.
  int get deduplicatedJoins => _deduplicator.joins;

  /// Registered interceptors.
  List<GuardInterceptor> get interceptors =>
      List<GuardInterceptor>.unmodifiable(_interceptors);

  /// Adds an interceptor. Request hooks run in registration order.
  void addInterceptor(GuardInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Removes an interceptor.
  void removeInterceptor(GuardInterceptor interceptor) {
    _interceptors.remove(interceptor);
  }

  /// Resets transport and dedup counters. Intended for demos and tests.
  void resetCounters() {
    _transportCalls = 0;
    _deduplicator.joins = 0;
  }

  /// Sends a GET request.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    CachePolicy? cachePolicy,
    List<String>? cacheTags,
    Duration? cacheTtl,
    bool? retry,
    void Function(ApiResponse<T> fresh)? onRevalidate,
  }) {
    return send<T>(
      'GET',
      path,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      cancelToken: cancelToken,
      deduplicate: deduplicate,
      cachePolicy: cachePolicy,
      cacheTags: cacheTags,
      cacheTtl: cacheTtl,
      retry: retry,
      onRevalidate: onRevalidate,
    );
  }

  /// Sends a POST request.
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    GuardMultipart? multipart,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    CachePolicy? cachePolicy,
    List<String>? cacheTags,
    Duration? cacheTtl,
    bool? retry,
    bool? queueIfOffline,
    int? priority,
  }) {
    return send<T>(
      'POST',
      path,
      data: data,
      multipart: multipart,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      cancelToken: cancelToken,
      deduplicate: deduplicate,
      cachePolicy: cachePolicy,
      cacheTags: cacheTags,
      cacheTtl: cacheTtl,
      retry: retry,
      queueIfOffline: queueIfOffline,
      priority: priority,
    );
  }

  /// Sends a PUT request.
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    GuardMultipart? multipart,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    CachePolicy? cachePolicy,
    List<String>? cacheTags,
    Duration? cacheTtl,
    bool? retry,
    bool? queueIfOffline,
    int? priority,
  }) {
    return send<T>(
      'PUT',
      path,
      data: data,
      multipart: multipart,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      cancelToken: cancelToken,
      deduplicate: deduplicate,
      cachePolicy: cachePolicy,
      cacheTags: cacheTags,
      cacheTtl: cacheTtl,
      retry: retry,
      queueIfOffline: queueIfOffline,
      priority: priority,
    );
  }

  /// Sends a PATCH request.
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    GuardMultipart? multipart,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    CachePolicy? cachePolicy,
    List<String>? cacheTags,
    Duration? cacheTtl,
    bool? retry,
    bool? queueIfOffline,
    int? priority,
  }) {
    return send<T>(
      'PATCH',
      path,
      data: data,
      multipart: multipart,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      cancelToken: cancelToken,
      deduplicate: deduplicate,
      cachePolicy: cachePolicy,
      cacheTags: cacheTags,
      cacheTtl: cacheTtl,
      retry: retry,
      queueIfOffline: queueIfOffline,
      priority: priority,
    );
  }

  /// Sends a DELETE request.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    CachePolicy? cachePolicy,
    List<String>? cacheTags,
    Duration? cacheTtl,
    bool? retry,
    bool? queueIfOffline,
    int? priority,
  }) {
    return send<T>(
      'DELETE',
      path,
      data: data,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      cancelToken: cancelToken,
      deduplicate: deduplicate,
      cachePolicy: cachePolicy,
      cacheTags: cacheTags,
      cacheTtl: cacheTtl,
      retry: retry,
      queueIfOffline: queueIfOffline,
      priority: priority,
    );
  }

  /// Sends a HEAD request.
  Future<ApiResponse<T>> head<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    bool? retry,
  }) {
    return send<T>(
      'HEAD',
      path,
      query: query,
      headers: headers,
      timeout: timeout,
      cancelToken: cancelToken,
      deduplicate: deduplicate,
      retry: retry,
    );
  }

  /// Uploads a multipart payload using POST.
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required GuardMultipart multipart,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? queueIfOffline,
    int? priority,
  }) {
    return post<T>(
      path,
      multipart: multipart,
      query: query,
      headers: headers,
      parser: parser,
      timeout: timeout,
      cancelToken: cancelToken,
      queueIfOffline: queueIfOffline,
      priority: priority,
    );
  }

  /// Downloads the response body as bytes.
  Future<ApiResponse<List<int>>> download(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    Duration? timeout,
    CancellationToken? cancelToken,
    Future<void> Function(List<int> bytes)? persist,
  }) async {
    final response = await send<List<int>>(
      'GET',
      path,
      query: query,
      headers: headers,
      timeout: timeout,
      cancelToken: cancelToken,
      cachePolicy: CachePolicy.networkOnly,
      rawBody: true,
      parser: (json) => json is List<int> ? json : <int>[],
    );
    if (persist != null && response.data != null) {
      await persist(response.data!);
    }
    return response;
  }

  /// Sends an arbitrary HTTP method.
  Future<ApiResponse<T>> send<T>(
    String method,
    String path, {
    Object? data,
    GuardMultipart? multipart,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    CachePolicy? cachePolicy,
    List<String>? cacheTags,
    Duration? cacheTtl,
    bool? retry,
    bool? queueIfOffline,
    int? priority,
    void Function(ApiResponse<T> fresh)? onRevalidate,
    bool rawBody = false,
  }) async {
    final started = DateTime.now();
    final requestId = createRequestId();
    final queryMap = _stringify(query);
    final url = resolve(path, queryMap);
    var request = GuardRequest(
      method: method.toUpperCase(),
      url: url,
      path: path,
      query: queryMap,
      headers: <String, String>{
        ..._config.network.defaultHeaders,
        if (_config.network.userAgent.isNotEmpty)
          'user-agent': _config.network.userAgent,
        ...?headers,
      },
      data: data,
      multipart: multipart,
      timeout:
          timeout ??
          _config.network.connectTimeout +
              _config.network.sendTimeout +
              _config.network.receiveTimeout,
      cancelToken: cancelToken,
      deduplicate: deduplicate ?? _config.network.enableDefaultDeduplication,
      cachePolicy: cachePolicy ?? _config.cache.defaultPolicy,
      cacheTags: cacheTags ?? const <String>[],
      cacheTtl: cacheTtl,
      retry: retry,
      queueIfOffline:
          queueIfOffline ??
          (_config.offline.queueMutationsByDefault &&
              _isMutation(method.toUpperCase())),
      priority: priority,
      requestId: requestId,
      rawBody: rawBody,
    );

    try {
      for (final interceptor in _interceptors) {
        request = await interceptor.onRequest(request);
      }
      var response = await _dispatch<T>(request, parser, onRevalidate);
      for (final interceptor in _interceptors.reversed) {
        response = await interceptor.onResponse(response) as ApiResponse<T>;
      }
      _recordMetric(request, response, started, failed: false);
      return response;
    } on FlutterGuardException catch (error) {
      var mapped = error;
      for (final interceptor in _interceptors.reversed) {
        mapped = await interceptor.onError(mapped);
      }
      _recordFailure(request, started, mapped);
      throw mapped;
    } catch (error) {
      final mapped = UnknownException(
        error.toString(),
        cause: error,
        requestId: request.requestId,
      );
      _recordFailure(request, started, mapped);
      throw mapped;
    }
  }

  /// [get] that returns [Result] instead of throwing Guard errors.
  Future<Result<ApiResponse<T>>> getResult<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? deduplicate,
    CachePolicy? cachePolicy,
    List<String>? cacheTags,
    Duration? cacheTtl,
    bool? retry,
    void Function(ApiResponse<T> fresh)? onRevalidate,
  }) {
    return _asResult(
      () => get<T>(
        path,
        query: query,
        headers: headers,
        parser: parser,
        timeout: timeout,
        cancelToken: cancelToken,
        deduplicate: deduplicate,
        cachePolicy: cachePolicy,
        cacheTags: cacheTags,
        cacheTtl: cacheTtl,
        retry: retry,
        onRevalidate: onRevalidate,
      ),
    );
  }

  /// [post] that returns [Result].
  Future<Result<ApiResponse<T>>> postResult<T>(
    String path, {
    Object? data,
    GuardMultipart? multipart,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
    Duration? timeout,
    CancellationToken? cancelToken,
    bool? retry,
    bool? queueIfOffline,
    int? priority,
  }) {
    return _asResult(
      () => post<T>(
        path,
        data: data,
        multipart: multipart,
        query: query,
        headers: headers,
        parser: parser,
        timeout: timeout,
        cancelToken: cancelToken,
        retry: retry,
        queueIfOffline: queueIfOffline,
        priority: priority,
      ),
    );
  }

  /// [put] that returns [Result].
  Future<Result<ApiResponse<T>>> putResult<T>(
    String path, {
    Object? data,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
  }) {
    return _asResult(
      () => put<T>(
        path,
        data: data,
        query: query,
        headers: headers,
        parser: parser,
      ),
    );
  }

  /// [patch] that returns [Result].
  Future<Result<ApiResponse<T>>> patchResult<T>(
    String path, {
    Object? data,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
  }) {
    return _asResult(
      () => patch<T>(
        path,
        data: data,
        query: query,
        headers: headers,
        parser: parser,
      ),
    );
  }

  /// [delete] that returns [Result].
  Future<Result<ApiResponse<T>>> deleteResult<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
    T Function(Object? json)? parser,
  }) {
    return _asResult(
      () => delete<T>(path, query: query, headers: headers, parser: parser),
    );
  }

  /// [head] that returns [Result].
  Future<Result<ApiResponse<T>>> headResult<T>(
    String path, {
    Map<String, Object?>? query,
    Map<String, String>? headers,
  }) {
    return _asResult(() => head<T>(path, query: query, headers: headers));
  }

  /// [send] that returns [Result].
  Future<Result<ApiResponse<T>>> sendResult<T>(
    String method,
    String path, {
    Object? data,
    T Function(Object? json)? parser,
  }) {
    return _asResult(() => send<T>(method, path, data: data, parser: parser));
  }

  /// Resolves [path] against [FlutterGuardConfig.baseUrl].
  Uri resolve(
    String path, [
    Map<String, String> query = const <String, String>{},
  ]) {
    final uri = Uri.parse(path);
    if (uri.hasScheme) {
      return query.isEmpty
          ? uri
          : uri.replace(
              queryParameters: <String, String>{
                ...uri.queryParameters,
                ...query,
              },
            );
    }
    final base = _config.baseUrl;
    if (base == null) {
      throw ArgumentError(
        'Relative path "$path" requires FlutterGuardConfig.baseUrl',
      );
    }
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$base$normalized',
    ).replace(queryParameters: query.isEmpty ? null : query);
  }

  Future<Result<ApiResponse<T>>> _asResult<T>(
    Future<ApiResponse<T>> Function() run,
  ) async {
    try {
      return Result.success(await run());
    } on FlutterGuardException catch (error) {
      return Result.failure(error);
    }
  }

  Future<ApiResponse<T>> _dispatch<T>(
    GuardRequest request,
    T Function(Object? json)? parser,
    void Function(ApiResponse<T> fresh)? onRevalidate,
  ) async {
    request.cancelToken?.throwIfCancelled(requestId: request.requestId);
    final policy = request.cachePolicy ?? CachePolicy.networkFirst;
    final cacheKey = _cache.keyFor(method: request.method, url: request.url);

    if (policy == CachePolicy.cacheOnly) {
      final cached = await _readCache(cacheKey, acceptStale: false);
      if (cached == null) {
        throw CacheException(
          'Cache miss for ${request.url}',
          requestId: request.requestId,
        );
      }
      return _responseFromCache<T>(request, cached, parser, stale: false);
    }

    if (policy == CachePolicy.cacheFirst) {
      final cached = await _readCache(cacheKey, acceptStale: false);
      if (cached != null) {
        return _responseFromCache<T>(request, cached, parser, stale: false);
      }
    }

    if (policy == CachePolicy.staleWhileRevalidate) {
      final cached = await _readCache(cacheKey, acceptStale: true);
      if (cached != null) {
        final stale = !cached.isFresh();
        final response = _responseFromCache<T>(
          request,
          cached,
          parser,
          stale: stale,
        );
        unawaited(
          _execute<T>(
                request.copyWith(cachePolicy: CachePolicy.networkOnly),
                parser,
                null,
              )
              .then((fresh) {
                onRevalidate?.call(fresh);
              })
              .catchError((Object _) {}),
        );
        return response;
      }
    }

    try {
      return await _maybeDedup<T>(request, parser);
    } on FlutterGuardException {
      if (policy == CachePolicy.networkFirst) {
        final cached = await _readCache(cacheKey, acceptStale: true);
        if (cached != null) {
          _logger.warning(
            'Network failed, serving cached response',
            metadata: <String, Object?>{'url': request.url.toString()},
          );
          return _responseFromCache<T>(request, cached, parser, stale: true);
        }
      }
      rethrow;
    }
  }

  Future<ApiResponse<T>> _maybeDedup<T>(
    GuardRequest request,
    T Function(Object? json)? parser,
  ) {
    if (!request.deduplicate) {
      return _execute<T>(request, parser, null);
    }
    return _deduplicator.join<T>(
      _deduplicator.keyFor(request),
      () => _execute<T>(request, parser, null),
    );
  }

  Future<ApiResponse<T>> _execute<T>(
    GuardRequest request,
    T Function(Object? json)? parser,
    void Function(ApiResponse<T> fresh)? onRevalidate,
  ) async {
    if (await _connectivity.refresh()) {
      if (request.queueIfOffline && _offline.enabled && request.isMutation) {
        final queued = await _offline.enqueue(
          method: request.method,
          path: request.path,
          query: request.query,
          headers: request.headers,
          data: request.data,
          priority: request.priority,
        );
        throw OfflineException(
          'Request queued for synchronization',
          requestId: request.requestId,
          queued: true,
          queueId: queued.id,
        );
      }
      throw OfflineException(
        'No network path is available',
        requestId: request.requestId,
      );
    }

    var attempt = 0;
    var retryCount = 0;

    while (true) {
      request.cancelToken?.throwIfCancelled(requestId: request.requestId);
      attempt += 1;
      try {
        final authorized = request.copyWith(
          headers: await _auth.authorize(request.headers),
        );
        _logger.debug(
          'HTTP ${authorized.method} ${authorized.url}',
          metadata: <String, Object?>{
            'requestId': authorized.requestId,
            'attempt': attempt,
            'headers': _logger.redactor.redactHeaders(authorized.headers),
          },
          requestId: authorized.requestId,
        );
        _transportCalls += 1;
        final raw = await _transport.send(authorized);
        final response = _parse<T>(authorized, raw, parser, retryCount);
        if (raw.statusCode >= 400) {
          throw _exceptionFor(raw, authorized.requestId);
        }
        await _writeCache(authorized, raw);
        _logger.info(
          'HTTP ${authorized.method} ${authorized.url} ${raw.statusCode}',
          metadata: <String, Object?>{
            'requestId': authorized.requestId,
            'statusCode': raw.statusCode,
            'retryCount': retryCount,
          },
          requestId: authorized.requestId,
        );
        return response;
      } on UnauthorizedException {
        if (_auth.canRefresh &&
            request.refreshAttempts < _auth.config.maxRefreshAttempts) {
          await _auth.refresh();
          request = request.copyWith(
            refreshAttempts: request.refreshAttempts + 1,
          );
          continue;
        }
        rethrow;
      } on FlutterGuardException catch (error) {
        final retryAfter = error is RateLimitException
            ? error.retryAfter
            : null;
        if (_retry.shouldRetry(
          attempt: attempt,
          idempotent: request.isIdempotent,
          requestOverride: request.retry,
          error: error,
        )) {
          final delay = _retry.delayFor(attempt, retryAfter: retryAfter);
          retryCount += 1;
          _logger.warning(
            'Retrying ${request.method} ${request.url}',
            metadata: <String, Object?>{
              'attempt': attempt + 1,
              'delayMs': delay.inMilliseconds,
              'error': error.message,
            },
            requestId: request.requestId,
          );
          await Future<void>.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
  }

  Future<CacheEntry?> _readCache(
    String key, {
    required bool acceptStale,
  }) async {
    final entry = await _cache.read(key, acceptStale: acceptStale);
    if (entry == null) {
      _metrics.recordCacheMiss();
    } else {
      _metrics.recordCacheHit();
    }
    return entry;
  }

  ApiResponse<T> _responseFromCache<T>(
    GuardRequest request,
    CacheEntry entry,
    T Function(Object? json)? parser, {
    required bool stale,
  }) {
    return ApiResponse<T>(
      data: _decode<T>(entry.body, parser),
      statusCode: entry.statusCode,
      headers: entry.headers,
      requestId: request.requestId,
      duration: Duration.zero,
      timestamp: DateTime.now(),
      fromCache: true,
      isStale: stale,
      url: request.url,
      method: request.method,
      responseSize: entry.body.length,
    );
  }

  Future<void> _writeCache(GuardRequest request, GuardRawResponse raw) async {
    if (!_cache.enabled || request.method != 'GET') {
      return;
    }
    if (request.cachePolicy == CachePolicy.networkOnly &&
        request.cacheTags.isEmpty) {
      // Still write when a TTL/tags were requested via cacheTtl.
    }
    final ttl = request.cacheTtl ?? _config.cache.defaultTtl;
    await _cache.write(
      CacheEntry(
        key: _cache.keyFor(method: request.method, url: request.url),
        body: utf8.decode(raw.bodyBytes, allowMalformed: true),
        statusCode: raw.statusCode,
        headers: raw.headers,
        storedAt: DateTime.now(),
        expiresAt: DateTime.now().add(ttl),
        tags: request.cacheTags,
        requestId: request.requestId,
      ),
    );
  }

  ApiResponse<T> _parse<T>(
    GuardRequest request,
    GuardRawResponse raw,
    T Function(Object? json)? parser,
    int retryCount,
  ) {
    Object? payload;
    if (request.rawBody) {
      payload = raw.bodyBytes;
    } else if (raw.bodyBytes.isNotEmpty) {
      final text = utf8.decode(raw.bodyBytes, allowMalformed: true);
      try {
        payload = jsonDecode(text);
      } on Object {
        payload = text;
      }
    }
    T? data;
    if (parser != null) {
      data = parser(payload);
    } else if (payload is T) {
      data = payload;
    } else if (payload == null) {
      data = null;
    } else {
      try {
        data = payload as T;
      } on Object {
        throw UnknownException(
          'Failed to parse response as $T',
          requestId: request.requestId,
          statusCode: raw.statusCode,
        );
      }
    }
    return ApiResponse<T>(
      data: data,
      statusCode: raw.statusCode,
      headers: raw.headers,
      requestId: request.requestId,
      duration: Duration.zero,
      timestamp: DateTime.now(),
      retryCount: retryCount,
      url: request.url,
      method: request.method,
      responseSize: raw.bodyBytes.length,
    );
  }

  T? _decode<T>(String body, T Function(Object? json)? parser) {
    if (body.isEmpty) {
      return parser == null ? null : parser(null);
    }
    Object? payload;
    try {
      payload = jsonDecode(body);
    } on Object {
      payload = body;
    }
    if (parser != null) {
      return parser(payload);
    }
    return payload is T ? payload : null;
  }

  FlutterGuardException _exceptionFor(GuardRawResponse raw, String requestId) {
    final body = utf8.decode(raw.bodyBytes, allowMalformed: true);
    final message = body.isEmpty ? 'HTTP ${raw.statusCode}' : body;
    switch (raw.statusCode) {
      case 401:
        return UnauthorizedException(message, requestId: requestId);
      case 403:
        return ForbiddenException(message, requestId: requestId);
      case 404:
        return NotFoundException(message, requestId: requestId);
      case 400:
      case 422:
        return ValidationException(
          message,
          requestId: requestId,
          statusCode: raw.statusCode,
        );
      case 408:
        return RequestTimeoutException(message, requestId: requestId);
      case 429:
        return RateLimitException(
          message,
          requestId: requestId,
          retryAfter: _retryAfter(raw.headers),
        );
      default:
        if (raw.statusCode >= 500) {
          return ServerException(
            message,
            requestId: requestId,
            statusCode: raw.statusCode,
          );
        }
        return NetworkException(
          message,
          requestId: requestId,
          statusCode: raw.statusCode,
        );
    }
  }

  Duration? _retryAfter(Map<String, String> headers) {
    final raw = headers['retry-after'];
    if (raw == null) {
      return null;
    }
    final seconds = int.tryParse(raw);
    if (seconds == null) {
      return null;
    }
    return Duration(seconds: seconds);
  }

  void _recordMetric(
    GuardRequest request,
    ApiResponse<dynamic> response,
    DateTime started, {
    required bool failed,
  }) {
    final duration = DateTime.now().difference(started);
    _metrics.record(
      RequestMetric(
        requestId: request.requestId,
        method: request.method,
        url: request.url.toString(),
        statusCode: response.statusCode,
        duration: duration,
        timestamp: DateTime.now(),
        retryCount: response.retryCount,
        responseSize: response.responseSize,
        fromCache: response.fromCache,
        failed: failed,
      ),
    );
  }

  void _recordFailure(
    GuardRequest request,
    DateTime started,
    FlutterGuardException error,
  ) {
    _logger.error(
      'HTTP ${request.method} ${request.url} failed',
      metadata: <String, Object?>{
        'requestId': request.requestId,
        'error': error.message,
        'statusCode': error.statusCode,
      },
      requestId: request.requestId,
    );
    _metrics.record(
      RequestMetric(
        requestId: request.requestId,
        method: request.method,
        url: request.url.toString(),
        statusCode: error.statusCode ?? 0,
        duration: DateTime.now().difference(started),
        timestamp: DateTime.now(),
        failed: true,
      ),
    );
  }

  Map<String, String> _stringify(Map<String, Object?>? query) {
    if (query == null || query.isEmpty) {
      return const <String, String>{};
    }
    return <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };
  }

  bool _isMutation(String method) {
    return method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
  }
}
