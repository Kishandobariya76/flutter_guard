import 'dart:async';

import 'connectivity_status.dart';

/// Source of connectivity updates.
///
/// FlutterGuard does not depend on `connectivity_plus`. Inject a platform
/// adapter if you already have one, or use [ManualConnectivityAdapter] in
/// tests and the example application.
abstract class ConnectivityAdapter {
  /// Current status.
  Future<ConnectivityStatus> current();

  /// Updates after [current].
  Stream<ConnectivityStatus> get statuses;
}

/// Controllable adapter used by tests, the example app, and as the default
/// when no [baseUrl] probe is configured.
class ManualConnectivityAdapter implements ConnectivityAdapter {
  /// Creates an adapter with an initial status.
  ManualConnectivityAdapter([this._status = ConnectivityStatus.online]);

  ConnectivityStatus _status;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  /// Last status passed to [setStatus] or the constructor.
  ConnectivityStatus get status => _status;

  /// Changes the reported status and notifies listeners.
  void setStatus(ConnectivityStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    if (!_controller.isClosed) {
      _controller.add(status);
    }
  }

  @override
  Future<ConnectivityStatus> current() async => _status;

  @override
  Stream<ConnectivityStatus> get statuses => _controller.stream;

  /// Releases the broadcast stream.
  Future<void> dispose() => _controller.close();
}
