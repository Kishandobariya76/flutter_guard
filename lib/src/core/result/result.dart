import '../exceptions/exceptions.dart';

/// A success-or-failure wrapper that avoids throwing for expected errors.
///
/// Use [Result] at application boundaries when both outcomes are routine.
/// Use exceptions when the caller is not expected to recover locally, or when
/// you want `try/catch` to match existing code.
///
/// ```dart
/// final result = await guard.network.getResult<User>(
///   '/users/123',
///   parser: User.fromJson,
/// );
/// result.when(
///   success: (response) => display(response.data),
///   failure: (error) => showError(error.message),
/// );
/// ```
sealed class Result<T> {
  /// Creates a result.
  const Result();

  /// Creates a successful result.
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result.
  const factory Result.failure(FlutterGuardException error) = Failure<T>;

  /// Whether this result is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Whether this result is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Unwraps the success value or throws [error].
  T get valueOrThrow {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>(:final error) => throw error,
    };
  }

  /// Returns the success value, or `null` when this is a failure.
  T? get valueOrNull {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>() => null,
    };
  }

  /// Returns the failure, or `null` when this is a success.
  FlutterGuardException? get errorOrNull {
    return switch (this) {
      Success<T>() => null,
      Failure<T>(:final error) => error,
    };
  }

  /// Pattern-matches both outcomes.
  R when<R>({
    required R Function(T value) success,
    required R Function(FlutterGuardException error) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Failure<T>(:final error) => failure(error),
    };
  }

  /// Maps a successful value and leaves failures unchanged.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => Result.success(transform(value)),
      Failure<T>(:final error) => Result.failure(error),
    };
  }
}

/// Successful [Result].
class Success<T> extends Result<T> {
  /// Creates a success.
  const Success(this.value);

  /// The produced value.
  final T value;
}

/// Failed [Result].
class Failure<T> extends Result<T> {
  /// Creates a failure.
  const Failure(this.error);

  /// The captured Guard error.
  final FlutterGuardException error;
}
