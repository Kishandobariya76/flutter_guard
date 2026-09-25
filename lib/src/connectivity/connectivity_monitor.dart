import 'dart:async';

import 'package:http/http.dart' as http;

import 'connectivity_adapter.dart';
import 'connectivity_status.dart';

/// Reports adapter connectivity and optional API reachability.
///
/// Connectivity answers "does a network path appear to exist?"
/// Reachability answers "did a request to [probeUri] succeed?"
class ConnectivityMonitor {
  /// Creates a monitor.
  ConnectivityMonitor({required ConnectivityAdapter adapter, this.probeUri})
    : _adapter = adapter;

  final ConnectivityAdapter _adapter;
  StreamSubscription<ConnectivityStatus>? _subscription;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _status = ConnectivityStatus.unknown;

  /// Optional URI used by [checkReachability].
  final Uri? probeUri;

  /// Last adapter status.
  ConnectivityStatus get status => _status;

  /// Adapter status changes.
  Stream<ConnectivityStatus> get onChange => _controller.stream;

  /// Underlying adapter, useful when it is a [ManualConnectivityAdapter].
  ConnectivityAdapter get adapter => _adapter;

  /// Starts listening to the adapter.
  Future<void> start() async {
    _status = await _adapter.current();
    _subscription = _adapter.statuses.listen((status) {
      _status = status;
      if (!_controller.isClosed) {
        _controller.add(status);
      }
    });
  }

  /// True when the last known adapter status is [ConnectivityStatus.offline].
  bool get isOffline => _status == ConnectivityStatus.offline;

  /// True when the last known adapter status is [ConnectivityStatus.online].
  bool get isOnline => _status == ConnectivityStatus.online;

  /// Reads the adapter again. Use this before a send so a just-changed
  /// [ManualConnectivityAdapter] is visible in the same event loop turn.
  Future<bool> refresh() async {
    _status = await _adapter.current();
    return isOffline;
  }

  /// Performs a real request to [uri] or [probeUri].
  ///
  /// A `2xx` or `3xx` status counts as reachable. Timeouts and transport
  /// errors count as unreachable. This is independent of [status].
  Future<bool> checkReachability({Uri? uri, Duration? timeout}) async {
    final target = uri ?? probeUri;
    if (target == null) {
      return false;
    }
    final client = http.Client();
    try {
      final response = await client
          .head(target)
          .timeout(timeout ?? const Duration(seconds: 5));
      return response.statusCode < 400;
    } on Object {
      return false;
    } finally {
      client.close();
    }
  }

  /// Releases subscriptions.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller.close();
  }
}
