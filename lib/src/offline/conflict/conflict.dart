/// How a `409 Conflict` is resolved during sync.
enum ConflictStrategy {
  /// Keep the server representation and drop the queued write.
  serverWins,

  /// Resend the client payload.
  clientWins,

  /// Prefer the payload with the later timestamp.
  lastWriteWins,

  /// Call [ConflictResolver].
  custom,

  /// Leave the entry in [OfflineQueueStatus.needsResolution].
  manual,
}

/// Inputs available to a conflict resolver.
class ConflictContext {
  /// Creates a context.
  const ConflictContext({
    required this.clientPayload,
    required this.serverPayload,
    this.clientUpdatedAt,
    this.serverUpdatedAt,
    this.path = '',
  });

  /// Body that was queued.
  final Object? clientPayload;

  /// Body returned by the server, when it could be parsed.
  final Object? serverPayload;

  /// Client timestamp, when known.
  final DateTime? clientUpdatedAt;

  /// Server timestamp, when known.
  final DateTime? serverUpdatedAt;

  /// Request path.
  final String path;
}

/// Produces a payload that should be written after a conflict.
typedef ConflictResolver = Future<Object?> Function(ConflictContext context);
