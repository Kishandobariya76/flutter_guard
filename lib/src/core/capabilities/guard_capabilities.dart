/// Runtime capabilities discovered during initialization.
class GuardCapabilities {
  /// Creates a capability snapshot.
  const GuardCapabilities({
    required this.persistentCache,
    required this.persistentQueue,
    required this.inspector,
    required this.diagnostics,
    required this.customTransport,
    required this.customStore,
  });

  /// Cache writes also go to [GuardKeyValueStore].
  final bool persistentCache;

  /// The offline queue is persisted.
  final bool persistentQueue;

  /// The inspector may be shown.
  final bool inspector;

  /// Logs and metrics are collected.
  final bool diagnostics;

  /// A caller-supplied [GuardTransport] is in use.
  final bool customTransport;

  /// A caller-supplied [GuardKeyValueStore] is in use.
  final bool customStore;
}
