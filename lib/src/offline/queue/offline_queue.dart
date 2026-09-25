import 'dart:async';
import 'dart:convert';

import '../../core/config/offline_config.dart';
import '../../core/exceptions/exceptions.dart';
import '../../storage/key_value_store.dart';
import '../../utils/request_id.dart';
import 'offline_queue_status.dart';
import 'offline_queued_request.dart';

/// Durable FIFO/priority queue for offline mutations.
class OfflineQueue {
  /// Creates a queue.
  OfflineQueue({
    required OfflineConfig config,
    required GuardKeyValueStore store,
  }) : _config = config,
       _store = store;

  final OfflineConfig _config;
  final GuardKeyValueStore _store;
  final List<OfflineQueuedRequest> _items = <OfflineQueuedRequest>[];
  final StreamController<List<OfflineQueuedRequest>> _controller =
      StreamController<List<OfflineQueuedRequest>>.broadcast();

  /// Current snapshot.
  List<OfflineQueuedRequest> get items =>
      List<OfflineQueuedRequest>.unmodifiable(_items);

  /// Updates after enqueue, status change, or removal.
  Stream<List<OfflineQueuedRequest>> get onChange => _controller.stream;

  /// Entries that still need work.
  List<OfflineQueuedRequest> get pending {
    return _items
        .where(
          (item) =>
              item.status == OfflineQueueStatus.pending ||
              item.status == OfflineQueueStatus.retrying,
        )
        .toList();
  }

  /// Number of unfinished entries.
  int get pendingCount => pending.length;

  /// Loads persisted entries.
  Future<void> hydrate() async {
    if (!_config.enabled || !_config.persistentQueue) {
      return;
    }
    final raw = await _store.read(_config.persistKey);
    if (raw == null) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _items
          ..clear()
          ..addAll(
            decoded.whereType<Map<dynamic, dynamic>>().map(
              (item) => OfflineQueuedRequest.fromJson(
                Map<String, Object?>.from(item),
              ),
            ),
          );
      }
    } on Object catch (error) {
      throw OfflineException(
        'Failed to restore the offline queue',
        cause: error,
      );
    }
    _emit();
  }

  /// Adds a request. Throws [OfflineException] when the queue is full.
  Future<OfflineQueuedRequest> enqueue({
    required String method,
    required String path,
    Map<String, String> query = const <String, String>{},
    Map<String, String> headers = const <String, String>{},
    Object? data,
    int? priority,
    DateTime? clientUpdatedAt,
  }) async {
    if (!_config.enabled) {
      throw const OfflineException('Offline queue is disabled');
    }
    if (_items.length >= _config.maxQueueSize) {
      throw const OfflineException('Offline queue is full');
    }
    final sanitized = <String, String>{
      for (final entry in headers.entries)
        if (!_isSecretHeader(entry.key)) entry.key: entry.value,
    };
    final item = OfflineQueuedRequest(
      id: createRequestId(),
      method: method,
      path: path,
      query: query,
      headers: sanitized,
      data: data,
      priority: priority ?? _config.defaultPriority,
      createdAt: DateTime.now(),
      clientUpdatedAt: clientUpdatedAt,
    );
    _items.add(item);
    await _persist();
    _emit();
    return item;
  }

  /// Changes priority of [id].
  Future<void> setPriority(String id, int priority) async {
    final item = _byId(id);
    item.priority = priority;
    await _persist();
    _emit();
  }

  /// Marks [id] as cancelled.
  Future<void> cancel(String id) async {
    final item = _byId(id);
    item.status = OfflineQueueStatus.cancelled;
    await _persist();
    _emit();
  }

  /// Moves a failed or cancelled entry back to pending.
  Future<void> retry(String id) async {
    final item = _byId(id);
    item.status = OfflineQueueStatus.pending;
    item.lastError = null;
    await _persist();
    _emit();
  }

  /// Updates status fields on [id].
  Future<void> update(
    String id, {
    OfflineQueueStatus? status,
    int? attempts,
    String? lastError,
  }) async {
    final item = _byId(id);
    if (status != null) {
      item.status = status;
    }
    if (attempts != null) {
      item.attempts = attempts;
    }
    if (lastError != null) {
      item.lastError = lastError;
    }
    await _persist();
    _emit();
  }

  /// Removes completed, failed, and cancelled entries.
  Future<void> clearFinished() async {
    _items.removeWhere(
      (item) =>
          item.status == OfflineQueueStatus.success ||
          item.status == OfflineQueueStatus.failed ||
          item.status == OfflineQueueStatus.cancelled,
    );
    await _persist();
    _emit();
  }

  /// Removes every entry.
  Future<void> clear() async {
    _items.clear();
    await _persist();
    _emit();
  }

  /// Next work item by priority, then creation time.
  OfflineQueuedRequest? nextWorkItem() {
    final open = pending;
    if (open.isEmpty) {
      return null;
    }
    open.sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) {
        return byPriority;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return open.first;
  }

  Future<void> _persist() async {
    if (!_config.persistentQueue) {
      return;
    }
    await _store.write(
      _config.persistKey,
      jsonEncode(_items.map((item) => item.toJson()).toList()),
    );
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(items);
    }
  }

  OfflineQueuedRequest _byId(String id) {
    return _items.firstWhere(
      (item) => item.id == id,
      orElse: () => throw OfflineException('Unknown queue entry $id'),
    );
  }

  bool _isSecretHeader(String name) {
    final lower = name.toLowerCase();
    return lower == 'authorization' || lower == 'cookie';
  }

  /// Closes the change stream.
  Future<void> dispose() => _controller.close();
}
