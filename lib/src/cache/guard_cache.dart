import 'dart:collection';
import 'dart:convert';

import '../core/config/cache_config.dart';
import '../core/exceptions/exceptions.dart';
import '../storage/key_value_store.dart';
import 'cache_entry.dart';

/// Memory plus optional persistent HTTP cache.
class GuardCache {
  /// Creates a cache.
  GuardCache({required CacheConfig config, required GuardKeyValueStore store})
    : _config = config,
      _store = store,
      _memory = LinkedHashMap<String, CacheEntry>();

  final CacheConfig _config;
  final GuardKeyValueStore _store;
  final LinkedHashMap<String, CacheEntry> _memory;

  /// Whether caching is enabled.
  bool get enabled => _config.enabled;

  /// In-memory entries, insertion order.
  List<CacheEntry> get entries => List<CacheEntry>.unmodifiable(_memory.values);

  /// Number of in-memory entries.
  int get length => _memory.length;

  /// Loads persisted entries into memory. Called during initialization.
  Future<void> hydrate() async {
    if (!_config.enabled || !_config.persistent) {
      return;
    }
    final keys = await _store.keys(_config.persistKeyPrefix);
    for (final key in keys) {
      final raw = await _store.read(key);
      if (raw == null) {
        continue;
      }
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          final entry = CacheEntry.fromJson(Map<String, Object?>.from(json));
          _memory[entry.key] = entry;
        }
      } on Object {
        await _store.delete(key);
      }
    }
  }

  /// Builds the canonical cache key for a request.
  String keyFor({required String method, required Uri url}) {
    return '$method ${url.toString()}';
  }

  /// Reads an entry without considering freshness.
  CacheEntry? peek(String key) => _memory[key];

  /// Reads an entry. When [acceptStale] is false, expired entries miss.
  Future<CacheEntry?> read(String key, {bool acceptStale = false}) async {
    if (!_config.enabled) {
      return null;
    }
    var entry = _memory[key];
    if (entry == null && _config.persistent) {
      final raw = await _store.read(_persistKey(key));
      if (raw != null) {
        try {
          final json = jsonDecode(raw);
          if (json is Map<String, dynamic>) {
            entry = CacheEntry.fromJson(Map<String, Object?>.from(json));
            _memory[key] = entry;
          }
        } on Object catch (error) {
          throw CacheException('Failed to decode cache entry', cause: error);
        }
      }
    }
    if (entry == null) {
      return null;
    }
    _touch(key, entry);
    if (!acceptStale && !entry.isFresh()) {
      return null;
    }
    return entry;
  }

  /// Writes an entry.
  Future<void> write(CacheEntry entry) async {
    if (!_config.enabled) {
      return;
    }
    _memory[entry.key] = entry;
    _evict();
    if (_config.persistent) {
      await _store.write(_persistKey(entry.key), jsonEncode(entry.toJson()));
    }
  }

  /// Removes the entry for [url], matching any method prefix when [method]
  /// is omitted.
  Future<void> invalidate(String url, {String? method}) async {
    final matches = _memory.keys.where((key) {
      if (method != null) {
        return key == '$method $url' || key.endsWith(' $url');
      }
      return key.endsWith(' $url') || key.contains(url);
    }).toList();
    for (final key in matches) {
      await _delete(key);
    }
  }

  /// Removes every entry tagged with [tag].
  Future<void> invalidateTag(String tag) async {
    final matches = _memory.entries
        .where((entry) => entry.value.tags.contains(tag))
        .map((entry) => entry.key)
        .toList();
    for (final key in matches) {
      await _delete(key);
    }
  }

  /// Removes every entry.
  Future<void> clear() async {
    _memory.clear();
    if (_config.persistent) {
      final keys = await _store.keys(_config.persistKeyPrefix);
      for (final key in keys) {
        await _store.delete(key);
      }
    }
  }

  Future<void> _delete(String key) async {
    _memory.remove(key);
    if (_config.persistent) {
      await _store.delete(_persistKey(key));
    }
  }

  void _touch(String key, CacheEntry entry) {
    _memory.remove(key);
    _memory[key] = entry;
  }

  void _evict() {
    while (_memory.length > _config.maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  String _persistKey(String cacheKey) {
    return '${_config.persistKeyPrefix}.$cacheKey';
  }
}
