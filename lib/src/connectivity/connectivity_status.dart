/// High-level network path reported by a [ConnectivityAdapter].
///
/// This is **not** the same as internet reachability. A device can be
/// [online] on a captive portal or LAN and still fail to reach your API.
enum ConnectivityStatus {
  /// No measurement is available yet.
  unknown,

  /// The adapter reports that no usable network path exists.
  offline,

  /// The adapter reports that a network path exists.
  online,
}
