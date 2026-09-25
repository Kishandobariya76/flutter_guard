/// One cached HTTP response.
class CacheEntry {
  /// Creates an entry.
  const CacheEntry({
    required this.key,
    required this.body,
    required this.statusCode,
    required this.headers,
    required this.storedAt,
    required this.expiresAt,
    this.tags = const <String>[],
    this.requestId,
  });

  /// Cache key, usually method + URL.
  final String key;

  /// UTF-8 body stored as a string.
  final String body;

  /// Original status.
  final int statusCode;

  /// Original headers.
  final Map<String, String> headers;

  /// When the entry was written.
  final DateTime storedAt;

  /// When the entry stops being fresh.
  final DateTime expiresAt;

  /// Invalidation tags.
  final List<String> tags;

  /// Request that wrote the entry.
  final String? requestId;

  /// Whether [now] is still inside [expiresAt].
  bool isFresh([DateTime? now]) => (now ?? DateTime.now()).isBefore(expiresAt);

  /// JSON representation used by the persistent store.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'key': key,
      'body': body,
      'statusCode': statusCode,
      'headers': headers,
      'storedAt': storedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'tags': tags,
      'requestId': requestId,
    };
  }

  /// Restores an entry from [toJson].
  factory CacheEntry.fromJson(Map<String, Object?> json) {
    return CacheEntry(
      key: json['key']! as String,
      body: json['body']! as String,
      statusCode: json['statusCode']! as int,
      headers: <String, String>{
        for (final entry in (json['headers']! as Map).entries)
          entry.key.toString(): entry.value.toString(),
      },
      storedAt: DateTime.parse(json['storedAt']! as String),
      expiresAt: DateTime.parse(json['expiresAt']! as String),
      tags: <String>[
        for (final tag in (json['tags'] as List<dynamic>? ?? const []))
          tag.toString(),
      ],
      requestId: json['requestId'] as String?,
    );
  }
}
