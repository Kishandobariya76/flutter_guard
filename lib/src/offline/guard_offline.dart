import '../core/config/offline_config.dart';
import 'conflict/conflict.dart';
import 'queue/offline_queue.dart';
import 'queue/offline_queued_request.dart';
import 'sync/guard_sync.dart';
import 'sync/sync_progress.dart';

/// Offline queue and synchronization facade.
class GuardOffline {
  /// Creates the facade.
  GuardOffline({
    required OfflineConfig config,
    required OfflineQueue queue,
    required GuardSync sync,
  }) : _config = config,
       _queue = queue,
       _sync = sync;

  final OfflineConfig _config;
  final OfflineQueue _queue;
  final GuardSync _sync;

  /// Whether the queue is enabled.
  bool get enabled => _config.enabled;

  /// Underlying queue.
  OfflineQueue get queue => _queue;

  /// Synchronization engine.
  GuardSync get syncEngine => _sync;

  /// Current entries.
  List<OfflineQueuedRequest> get items => _queue.items;

  /// Queue changes.
  Stream<List<OfflineQueuedRequest>> get onQueueChange => _queue.onChange;

  /// Sync progress.
  Stream<SyncProgress> get onSyncProgress => _sync.onProgress;

  /// Enqueues a request.
  Future<OfflineQueuedRequest> enqueue({
    required String method,
    required String path,
    Map<String, String> query = const <String, String>{},
    Map<String, String> headers = const <String, String>{},
    Object? data,
    int? priority,
    DateTime? clientUpdatedAt,
  }) {
    return _queue.enqueue(
      method: method,
      path: path,
      query: query,
      headers: headers,
      data: data,
      priority: priority,
      clientUpdatedAt: clientUpdatedAt,
    );
  }

  /// Changes an entry's priority.
  Future<void> setPriority(String id, int priority) {
    return _queue.setPriority(id, priority);
  }

  /// Cancels an entry.
  Future<void> cancel(String id) => _queue.cancel(id);

  /// Requeues a failed entry.
  Future<void> retry(String id) => _queue.retry(id);

  /// Drains the queue.
  Future<SyncProgress> sync() => _sync.synchronize();

  /// Sets the conflict strategy used during sync.
  void setConflictStrategy(
    ConflictStrategy strategy, {
    ConflictResolver? resolver,
  }) {
    _sync.strategy = strategy;
    if (resolver != null) {
      _sync.resolver = resolver;
    }
  }

  /// Current sync snapshot.
  SyncProgress progress() => _sync.snapshot();
}
