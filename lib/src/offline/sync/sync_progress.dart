/// Snapshot of an offline synchronization run.
class SyncProgress {
  /// Creates a progress snapshot.
  const SyncProgress({
    required this.queue,
    required this.completed,
    required this.processing,
    required this.pending,
    required this.failed,
    required this.cancelled,
    required this.needsResolution,
    this.running = false,
  });

  /// Total entries considered.
  final int queue;

  /// Successfully sent.
  final int completed;

  /// Currently sending.
  final int processing;

  /// Not yet sent.
  final int pending;

  /// Permanently failed.
  final int failed;

  /// Cancelled.
  final int cancelled;

  /// Waiting for manual conflict resolution.
  final int needsResolution;

  /// Whether a sync loop is active.
  final bool running;
}
