/// Guarantees at most one execution per [duration].
///
/// Leading-edge: the first call in a window runs immediately. Later calls
/// inside the window are ignored.
class Throttler {
  /// Creates a throttler.
  Throttler({this.duration = const Duration(milliseconds: 300)});

  /// Minimum spacing between executions.
  final Duration duration;

  DateTime? _last;
  int _scheduled = 0;
  int _executed = 0;

  /// How many times [run] was invoked.
  int get scheduled => _scheduled;

  /// How many times the callback actually ran.
  int get executed => _executed;

  /// Runs [action] when the window is open.
  bool run(void Function() action) {
    _scheduled += 1;
    final now = DateTime.now();
    if (_last != null && now.difference(_last!) < duration) {
      return false;
    }
    _last = now;
    _executed += 1;
    action();
    return true;
  }

  /// Clears the window and counters.
  void reset() {
    _last = null;
    _scheduled = 0;
    _executed = 0;
  }
}
