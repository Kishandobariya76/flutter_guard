/// Small persistence port shared by cache, the offline queue, and flags.
abstract class GuardKeyValueStore {
  /// Reads a string value.
  Future<String?> read(String key);

  /// Writes a string value.
  Future<void> write(String key, String value);

  /// Deletes a key.
  Future<void> delete(String key);

  /// Lists keys that start with [prefix].
  Future<List<String>> keys([String prefix = '']);

  /// Removes every key.
  Future<void> clear();
}

/// Process-local store. Data is lost when the isolate dies.
class MemoryKeyValueStore implements GuardKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  /// Current snapshot, useful in tests.
  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_values);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<List<String>> keys([String prefix = '']) async {
    return _values.keys.where((key) => key.startsWith(prefix)).toList();
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }
}
