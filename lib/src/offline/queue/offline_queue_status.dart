/// Lifecycle of one queued request.
enum OfflineQueueStatus {
  /// Waiting to be sent.
  pending,

  /// Currently being sent.
  processing,

  /// Waiting to retry after a failure.
  retrying,

  /// Sent successfully.
  success,

  /// Failed and will not be retried automatically.
  failed,

  /// Cancelled by the caller.
  cancelled,

  /// Waiting for a [ConflictStrategy.manual] decision.
  needsResolution,
}
