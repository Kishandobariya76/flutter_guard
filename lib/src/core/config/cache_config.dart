import '../../network/cache_policy.dart';

/// In-memory and persistent cache settings.
class CacheConfig {
  /// Creates cache settings.
  const CacheConfig({
    this.enabled = true,
    this.defaultTtl = const Duration(minutes: 10),
    this.defaultPolicy = CachePolicy.networkFirst,
    this.maxMemoryEntries = 256,
    this.persistent = false,
    this.persistKeyPrefix = 'flutter_guard.cache',
  });

  /// Whether caching is active.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Lets you disable cache globally without removing call-site
  /// policies.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `CacheConfig(enabled: true)`
  /// **Production recommendation:** Keep enabled for read-heavy screens.
  /// **Common mistakes:** Disabling cache and then wondering why SWR is unused.
  final bool enabled;

  /// How long a written entry stays fresh.
  ///
  /// **Type:** `Duration`
  /// **Required:** no
  /// **Default:** `10 minutes`
  /// **Purpose:** Controls when [CachePolicy.cacheFirst] considers an entry
  /// usable without a network call.
  /// **Allowed values:** Any positive duration.
  /// **Example:** `CacheConfig(defaultTtl: Duration(minutes: 10))`
  /// **Production recommendation:** Match data volatility. User profiles can
  /// live longer than prices.
  /// **Common mistakes:** Using a multi-hour TTL for personalized data.
  final Duration defaultTtl;

  /// Policy used when a request does not specify one.
  ///
  /// **Type:** [CachePolicy]
  /// **Required:** no
  /// **Default:** [CachePolicy.networkFirst]
  /// **Purpose:** Sets a safe default that prefers fresh data.
  /// **Allowed values:** Any [CachePolicy].
  /// **Example:** `CacheConfig(defaultPolicy: CachePolicy.networkFirst)`
  /// **Production recommendation:** `networkFirst` or `staleWhileRevalidate`.
  /// **Common mistakes:** Using `cacheOnly` as a global default.
  final CachePolicy defaultPolicy;

  /// Maximum number of entries kept in memory.
  ///
  /// **Type:** `int`
  /// **Required:** no
  /// **Default:** `256`
  /// **Purpose:** Bounds memory use with LRU eviction.
  /// **Allowed values:** `1` or greater.
  /// **Example:** `CacheConfig(maxMemoryEntries: 256)`
  /// **Production recommendation:** Tune against payload size, not just count.
  /// **Common mistakes:** Storing large binary downloads in the response cache.
  final int maxMemoryEntries;

  /// Whether entries are also written to [GuardKeyValueStore].
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `false`
  /// **Purpose:** Survives process restarts when a store is configured.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `CacheConfig(persistent: false)`
  /// **Production recommendation:** Enable only for non-sensitive read models.
  /// **Common mistakes:** Persisting authenticated payloads to an open file.
  final bool persistent;

  /// Key prefix used in the persistent store.
  ///
  /// **Type:** `String`
  /// **Required:** no
  /// **Default:** `flutter_guard.cache`
  /// **Purpose:** Avoids colliding with other keys in a shared store.
  /// **Allowed values:** Any non-empty string.
  /// **Example:** `CacheConfig(persistKeyPrefix: 'flutter_guard.cache')`
  /// **Production recommendation:** Include an app-specific prefix.
  /// **Common mistakes:** Sharing a prefix with the offline queue.
  final String persistKeyPrefix;

  /// Default cache settings.
  static const CacheConfig defaults = CacheConfig();
}
