import 'dart:async';

/// Collapses a burst of calls into one execution after [duration] of silence.
///
/// ```dart
/// final debouncer = Debouncer(duration: Duration(milliseconds: 300));
/// onChanged: (text) {
///   debouncer.run(() => guard.network.get('/search', query: {'q': text}));
/// };
/// ```
class Debouncer {
  /// Creates a debouncer.
  Debouncer({this.duration = const Duration(milliseconds: 300)});

  /// Quiet period required before [run] executes.
  final Duration duration;

  Timer? _timer;
  int _scheduled = 0;
  int _executed = 0;

  /// How many times [run] was invoked.
  int get scheduled => _scheduled;

  /// How many times the callback actually ran.
  int get executed => _executed;

  /// Whether a timer is waiting.
  bool get isPending => _timer?.isActive ?? false;

  /// Schedules [action], cancelling any previously scheduled action.
  void run(void Function() action) {
    _scheduled += 1;
    _timer?.cancel();
    _timer = Timer(duration, () {
      _executed += 1;
      action();
    });
  }

  /// Cancels a pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels and resets counters.
  void reset() {
    cancel();
    _scheduled = 0;
    _executed = 0;
  }

  /// Releases the timer.
  void dispose() => cancel();
}
