/// Offline queue and synchronization settings.
class OfflineConfig {
  /// Creates offline settings.
  const OfflineConfig({
    this.enabled = true,
    this.persistentQueue = true,
    this.autoSync = true,
    this.maxQueueSize = 500,
    this.defaultPriority = 0,
    this.queueMutationsByDefault = true,
    this.persistKey = 'flutter_guard.offline.queue',
  });

  /// Whether the offline queue is active.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Allows mutation queuing when connectivity is offline.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `OfflineConfig(enabled: true)`
  /// **Production recommendation:** Enable if users can work without a network.
  /// **Common mistakes:** Queuing GET requests that should fail fast.
  final bool enabled;

  /// Whether queued requests are written to [GuardKeyValueStore].
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Restores unfinished work after a process restart.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `OfflineConfig(persistentQueue: true)`
  /// **Production recommendation:** Enable, and encrypt the store if bodies
  /// may contain personal data.
  /// **Common mistakes:** Persisting secrets in the request body.
  final bool persistentQueue;

  /// Whether connectivity returning to online starts a sync automatically.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Drains the queue without a manual trigger.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `OfflineConfig(autoSync: true)`
  /// **Production recommendation:** Keep enabled.
  /// **Common mistakes:** Calling `sync` in a tight loop while this is on.
  final bool autoSync;

  /// Maximum number of pending entries.
  ///
  /// **Type:** `int`
  /// **Required:** no
  /// **Default:** `500`
  /// **Purpose:** Protects disk and memory if the device stays offline.
  /// **Allowed values:** `1` or greater.
  /// **Example:** `OfflineConfig(maxQueueSize: 500)`
  /// **Production recommendation:** Size this to your worst offline session.
  /// **Common mistakes:** Letting the queue grow without a user-visible limit.
  final int maxQueueSize;

  /// Priority assigned when enqueueing without an override.
  ///
  /// **Type:** `int`
  /// **Required:** no
  /// **Default:** `0`
  /// **Purpose:** Higher values are synchronized first.
  /// **Allowed values:** Any integer.
  /// **Example:** `OfflineConfig(defaultPriority: 0)`
  /// **Production recommendation:** Reserve higher values for user-critical
  /// writes.
  /// **Common mistakes:** Giving every request the same high priority.
  final int defaultPriority;

  /// Whether POST, PUT, PATCH, and DELETE queue automatically when offline.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Makes offline writes work without per-call flags.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `OfflineConfig(queueMutationsByDefault: true)`
  /// **Production recommendation:** Enable for draft-style writes.
  /// **Common mistakes:** Assuming GETs are also queued. They are not.
  final bool queueMutationsByDefault;

  /// Persistent store key for the queue snapshot.
  ///
  /// **Type:** `String`
  /// **Required:** no
  /// **Default:** `flutter_guard.offline.queue`
  /// **Purpose:** Isolates queue data in a shared store.
  /// **Allowed values:** Any non-empty string.
  /// **Example:** `OfflineConfig(persistKey: 'flutter_guard.offline.queue')`
  /// **Production recommendation:** Include an app-specific prefix.
  /// **Common mistakes:** Sharing this key across environments.
  final String persistKey;

  /// Default offline settings.
  static const OfflineConfig defaults = OfflineConfig();
}
