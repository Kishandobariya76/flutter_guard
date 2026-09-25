/// How a request interacts with the cache.
enum CachePolicy {
  /// Always call the network. The response may still be written to cache.
  networkOnly,

  /// Read only from cache. Throws [CacheException] on a miss.
  cacheOnly,

  /// Return a fresh cache entry when one exists, otherwise call the network.
  cacheFirst,

  /// Call the network first. Fall back to cache when the network fails.
  networkFirst,

  /// Return a cache entry immediately, including stale entries, and refresh
  /// the cache in the background.
  staleWhileRevalidate,
}
