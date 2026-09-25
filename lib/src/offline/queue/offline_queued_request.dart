import 'offline_queue_status.dart';

/// One persisted offline request.
class OfflineQueuedRequest {
  /// Creates a queued request.
  OfflineQueuedRequest({
    required this.id,
    required this.method,
    required this.path,
    required this.createdAt,
    this.query = const <String, String>{},
    this.headers = const <String, String>{},
    this.data,
    this.priority = 0,
    this.status = OfflineQueueStatus.pending,
    this.attempts = 0,
    this.lastError,
    this.clientUpdatedAt,
  });

  /// Queue identifier.
  final String id;

  /// HTTP method.
  final String method;

  /// Request path or URL.
  final String path;

  /// Query parameters.
  final Map<String, String> query;

  /// Headers with secrets stripped.
  final Map<String, String> headers;

  /// JSON-encodable body.
  final Object? data;

  /// Higher values are synchronized first.
  int priority;

  /// Current status.
  OfflineQueueStatus status;

  /// Send attempts so far.
  int attempts;

  /// Last failure message.
  String? lastError;

  /// When the entry was created.
  final DateTime createdAt;

  /// Optional client write time used by last-write-wins.
  final DateTime? clientUpdatedAt;

  /// JSON representation.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'method': method,
      'path': path,
      'query': query,
      'headers': headers,
      'data': data,
      'priority': priority,
      'status': status.name,
      'attempts': attempts,
      'lastError': lastError,
      'createdAt': createdAt.toIso8601String(),
      'clientUpdatedAt': clientUpdatedAt?.toIso8601String(),
    };
  }

  /// Restores an entry from [toJson].
  factory OfflineQueuedRequest.fromJson(Map<String, Object?> json) {
    return OfflineQueuedRequest(
      id: json['id']! as String,
      method: json['method']! as String,
      path: json['path']! as String,
      query: <String, String>{
        for (final entry in (json['query'] as Map? ?? const {}).entries)
          entry.key.toString(): entry.value.toString(),
      },
      headers: <String, String>{
        for (final entry in (json['headers'] as Map? ?? const {}).entries)
          entry.key.toString(): entry.value.toString(),
      },
      data: json['data'],
      priority: json['priority'] as int? ?? 0,
      status: OfflineQueueStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => OfflineQueueStatus.pending,
      ),
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      createdAt: DateTime.parse(json['createdAt']! as String),
      clientUpdatedAt: json['clientUpdatedAt'] == null
          ? null
          : DateTime.parse(json['clientUpdatedAt']! as String),
    );
  }
}
