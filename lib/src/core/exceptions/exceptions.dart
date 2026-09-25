/// Root exception for every recoverable FlutterGuard failure.
///
/// **When it occurs:** A Guard API cannot complete the requested operation.
/// **Properties:** [message], optional [cause], optional [requestId], optional
/// [statusCode].
/// **How to handle:** Catch this type to cover all Guard errors, or catch a
/// subclass when the recovery path is specific.
/// **Retry behavior:** Not retryable by default. Subclasses document their own
/// retry policy.
///
/// ```dart
/// try {
///   await guard.network.get('/users/1');
/// } on FlutterGuardException catch (error) {
///   guard.logger.error('Request failed', metadata: {'error': error.message});
/// }
/// ```
class FlutterGuardException implements Exception {
  /// Creates a Guard exception.
  const FlutterGuardException(
    this.message, {
    this.cause,
    this.requestId,
    this.statusCode,
  });

  /// Human-readable description of the failure.
  final String message;

  /// Underlying error, if one was captured.
  final Object? cause;

  /// Request identifier associated with the failure, when available.
  final String? requestId;

  /// HTTP status code associated with the failure, when available.
  final int? statusCode;

  @override
  String toString() => '$runtimeType: $message';
}

/// A network-level failure that is not represented by a more specific type.
///
/// **When it occurs:** The transport fails, DNS fails, or an unexpected HTTP
/// status is returned.
/// **Retry behavior:** Retryable when the status is in
/// [RetryConfig.retryableStatusCodes] or the cause is a transient I/O error.
class NetworkException extends FlutterGuardException {
  /// Creates a network exception.
  const NetworkException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode,
  });
}

/// The request exceeded its connect, send, or receive timeout.
///
/// **When it occurs:** The transport does not finish before the configured
/// timeout.
/// **Retry behavior:** Retryable for idempotent methods.
///
/// Named [RequestTimeoutException] to avoid colliding with `dart:async`
/// `TimeoutException`.
class RequestTimeoutException extends FlutterGuardException {
  /// Creates a timeout exception.
  const RequestTimeoutException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode,
    this.timeout,
  });

  /// Timeout that was exceeded, when known.
  final Duration? timeout;
}

/// The server rejected the request because authentication is missing or invalid.
///
/// **When it occurs:** HTTP 401, or a refresh attempt fails.
/// **Retry behavior:** FlutterGuard retries the original request once after a
/// successful token refresh. If refresh fails, this exception is thrown.
class UnauthorizedException extends FlutterGuardException {
  /// Creates an unauthorized exception.
  const UnauthorizedException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode = 401,
  });
}

/// The authenticated caller is not allowed to perform the request.
///
/// **When it occurs:** HTTP 403.
/// **Retry behavior:** Not retryable. Refreshing the access token will not
/// change authorization.
class ForbiddenException extends FlutterGuardException {
  /// Creates a forbidden exception.
  const ForbiddenException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode = 403,
  });
}

/// The requested resource does not exist.
///
/// **When it occurs:** HTTP 404.
/// **Retry behavior:** Not retryable unless the resource is expected to appear
/// shortly and the caller opts in.
class NotFoundException extends FlutterGuardException {
  /// Creates a not-found exception.
  const NotFoundException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode = 404,
  });
}

/// The server rejected the payload as invalid.
///
/// **When it occurs:** HTTP 400 or 422.
/// **Retry behavior:** Not retryable until the caller fixes the payload.
class ValidationException extends FlutterGuardException {
  /// Creates a validation exception.
  const ValidationException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode = 422,
    this.fieldErrors = const <String, List<String>>{},
  });

  /// Optional field-level errors parsed from the response body.
  final Map<String, List<String>> fieldErrors;
}

/// The server asked the client to slow down.
///
/// **When it occurs:** HTTP 429.
/// **Retry behavior:** Retryable. FlutterGuard honors [Retry-After] when the
/// header is a delay in seconds.
class RateLimitException extends FlutterGuardException {
  /// Creates a rate-limit exception.
  const RateLimitException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode = 429,
    this.retryAfter,
  });

  /// Server-requested delay before the next attempt.
  final Duration? retryAfter;
}

/// The server failed to process a valid request.
///
/// **When it occurs:** HTTP 5xx.
/// **Retry behavior:** Retryable for idempotent methods.
class ServerException extends FlutterGuardException {
  /// Creates a server exception.
  const ServerException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode,
  });
}

/// The caller cancelled the request.
///
/// **When it occurs:** [CancellationToken.cancel] is invoked before completion.
/// **Retry behavior:** Never retry a cancelled request.
class CancelledException extends FlutterGuardException {
  /// Creates a cancellation exception.
  const CancelledException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode,
  });
}

/// A cache read or write failed.
///
/// **When it occurs:** Persistence is unavailable, an entry is corrupt, or a
/// cache-only read misses.
/// **Retry behavior:** Not retryable automatically. Callers may fall back to
/// the network.
class CacheException extends FlutterGuardException {
  /// Creates a cache exception.
  const CacheException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode,
  });
}

/// The operation cannot proceed because the client is offline.
///
/// **When it occurs:** Connectivity is [ConnectivityStatus.offline] and the
/// request was not queued.
/// **Retry behavior:** Queue the request or wait for connectivity.
class OfflineException extends FlutterGuardException {
  /// Creates an offline exception.
  const OfflineException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode,
    this.queued = false,
    this.queueId,
  });

  /// Whether the request was written to the offline queue.
  final bool queued;

  /// Queue entry id when [queued] is true.
  final String? queueId;
}

/// An unexpected failure that does not fit a more specific type.
///
/// **When it occurs:** A parser throws, or an unknown error escapes the
/// pipeline.
/// **Retry behavior:** Not retryable by default.
class UnknownException extends FlutterGuardException {
  /// Creates an unknown exception.
  const UnknownException(
    super.message, {
    super.cause,
    super.requestId,
    super.statusCode,
  });
}
