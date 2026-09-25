import 'dart:async';

import 'package:flutter/widgets.dart';

/// Observes [AppLifecycleState] and keeps a history for the example and
/// inspector.
class AppLifecycleMonitor with WidgetsBindingObserver {
  final List<AppLifecycleState> _history = <AppLifecycleState>[];
  final StreamController<AppLifecycleState> _controller =
      StreamController<AppLifecycleState>.broadcast();
  bool _attached = false;

  /// Recorded events, oldest first.
  List<AppLifecycleState> get history =>
      List<AppLifecycleState>.unmodifiable(_history);

  /// Latest state, if any.
  AppLifecycleState? get current => _history.isEmpty ? null : _history.last;

  /// Live updates.
  Stream<AppLifecycleState> get onChange => _controller.stream;

  /// Registers with [WidgetsBinding]. Safe to call more than once.
  void attach() {
    if (_attached) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null) {
      _record(state);
    }
    _attached = true;
  }

  /// Removes the observer.
  void detach() {
    if (!_attached) {
      return;
    }
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _record(state);
  }

  void _record(AppLifecycleState state) {
    _history.add(state);
    if (_history.length > 100) {
      _history.removeAt(0);
    }
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  /// Clears recorded events.
  void clear() {
    _history.clear();
  }

  /// Detaches and closes the stream.
  Future<void> dispose() async {
    detach();
    await _controller.close();
  }
}
