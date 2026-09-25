/// Replaces known secret values before they are logged or shown in the
/// inspector.
class LogRedactor {
  /// Creates a redactor.
  LogRedactor({
    this.enabled = true,
    Iterable<String> extraKeys = const <String>[],
  }) : extraKeys = extraKeys
           .map(
             (key) => key.toLowerCase().replaceAll('-', '').replaceAll('_', ''),
           )
           .toSet();

  /// Built-in keys matched case-insensitively.
  static const Set<String> defaultKeys = <String>{
    'authorization',
    'cookie',
    'password',
    'token',
    'accesstoken',
    'refreshtoken',
    'creditcard',
    'secret',
    'apikey',
    'access_token',
    'refresh_token',
    'api_key',
    'credit_card',
  };

  /// Whether redaction is active.
  final bool enabled;

  /// Additional keys supplied by the app.
  final Set<String> extraKeys;

  /// Placeholder written in place of a secret.
  static const String mask = '********';

  /// Returns whether [key] should be redacted.
  bool isSensitive(String key) {
    if (!enabled) {
      return false;
    }
    final normalized = _normalize(key);
    return defaultKeys.contains(normalized) || extraKeys.contains(normalized);
  }

  /// Redacts values in a header or metadata map.
  Map<String, Object?> redactMap(Map<String, Object?> input) {
    if (!enabled) {
      return Map<String, Object?>.of(input);
    }
    return <String, Object?>{
      for (final entry in input.entries)
        entry.key: isSensitive(entry.key)
            ? mask
            : _redactValue(entry.key, entry.value),
    };
  }

  /// Redacts a header map.
  Map<String, String> redactHeaders(Map<String, String> headers) {
    if (!enabled) {
      return Map<String, String>.of(headers);
    }
    return <String, String>{
      for (final entry in headers.entries)
        entry.key: isSensitive(entry.key)
            ? _maskHeader(entry.value)
            : entry.value,
    };
  }

  Object? _redactValue(String key, Object? value) {
    if (value is Map) {
      return redactMap(
        value.map((mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue)),
      );
    }
    if (value is List) {
      return value.map((item) => _redactValue(key, item)).toList();
    }
    if (value is String && isSensitive(key)) {
      return mask;
    }
    return value;
  }

  String _maskHeader(String value) {
    final parts = value.split(' ');
    if (parts.length == 2 && parts[1].isNotEmpty) {
      return '${parts[0]} $mask';
    }
    return mask;
  }

  String _normalize(String key) {
    return key.toLowerCase().replaceAll('-', '').replaceAll('_', '');
  }
}
