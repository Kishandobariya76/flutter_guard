import 'dart:math';

import '../../core/config/retry_config.dart';
import '../../core/exceptions/exceptions.dart';

/// Computes retry delays and decides whether another attempt is allowed.
class RetryEngine {
  /// Creates an engine.
  RetryEngine(this.config, {Random? random}) : _random = random ?? Random();

  /// Active policy.
  final RetryConfig config;
  final Random _random;

  /// Whether another attempt should be made after [attempt] failed.
  ///
  /// [attempt] is 1-based and already includes the failed try.
  bool shouldRetry({
    required int attempt,
    required bool idempotent,
    required bool? requestOverride,
    FlutterGuardException? error,
  }) {
    if (attempt >= config.maxAttempts) {
      return false;
    }
    if (error is CancelledException) {
      return false;
    }
    final allowNonIdempotent = requestOverride ?? config.retryNonIdempotent;
    if (!idempotent && !allowNonIdempotent) {
      return false;
    }
    if (requestOverride == false) {
      return false;
    }
    if (error is ValidationException ||
        error is ForbiddenException ||
        error is NotFoundException ||
        error is UnauthorizedException) {
      return false;
    }
    final status = error?.statusCode;
    if (status != null && !config.retryableStatusCodes.contains(status)) {
      return false;
    }
    return true;
  }

  /// Delay before the next attempt. [attempt] is the failed try (1-based).
  Duration delayFor(int attempt, {Duration? retryAfter}) {
    if (retryAfter != null && retryAfter > Duration.zero) {
      return _cap(retryAfter);
    }
    var delay = config.initialDelay;
    if (config.exponentialBackoff && attempt > 1) {
      final factor = 1 << (attempt - 1);
      delay = config.initialDelay * factor;
    }
    delay = _cap(delay);
    if (config.jitter && delay > Duration.zero) {
      final maxJitter = delay.inMilliseconds;
      if (maxJitter > 0) {
        final extra = _random.nextInt(maxJitter + 1);
        delay = Duration(milliseconds: delay.inMilliseconds + extra);
        delay = _cap(delay);
      }
    }
    return delay;
  }

  Duration _cap(Duration delay) {
    if (delay > config.maxDelay) {
      return config.maxDelay;
    }
    if (delay < Duration.zero) {
      return Duration.zero;
    }
    return delay;
  }
}
