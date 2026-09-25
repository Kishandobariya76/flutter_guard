import 'dart:async';

import '../../core/exceptions/exceptions.dart';

/// Cooperative cancellation handle for a single request or a group of requests.
class CancellationToken {
  bool _cancelled = false;
  Object? _reason;
  final List<void Function()> _listeners = <void Function()>[];

  /// Whether [cancel] has been called.
  bool get isCancelled => _cancelled;

  /// Reason supplied to [cancel], if any.
  Object? get reason => _reason;

  /// Throws [CancelledException] when the token is already cancelled.
  void throwIfCancelled({String? requestId}) {
    if (_cancelled) {
      throw CancelledException(
        'Request was cancelled',
        cause: _reason,
        requestId: requestId,
      );
    }
  }

  /// Registers a listener invoked once when the token is cancelled.
  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  /// Removes a previously registered listener.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Cancels the token and notifies listeners.
  void cancel([Object? reason]) {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    _reason = reason;
    final listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }
}

/// Completes a [Completer] when [token] is cancelled.
void bindCancellation(CancellationToken? token, Completer<void> abort) {
  if (token == null) {
    return;
  }
  token.addListener(() {
    if (!abort.isCompleted) {
      abort.complete();
    }
  });
}
