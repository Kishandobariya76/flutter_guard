import 'dart:async';
import 'dart:convert';

import '../../core/exceptions/exceptions.dart';
import '../conflict/conflict.dart';
import '../queue/offline_queue.dart';
import '../queue/offline_queue_status.dart';
import '../queue/offline_queued_request.dart';
import 'sync_progress.dart';

/// Sends a queued request and returns status plus optional parsed body.
typedef OfflineSendHandler =
    Future<({int statusCode, Object? body})> Function(
      OfflineQueuedRequest item, {
      Object? overrideData,
    });

/// Drains the offline queue when connectivity returns.
class GuardSync {
  /// Creates a sync engine.
  GuardSync({
    required OfflineQueue queue,
    required OfflineSendHandler sender,
    this.strategy = ConflictStrategy.serverWins,
    this.resolver,
  }) : _queue = queue,
       _sender = sender;

  final OfflineQueue _queue;
  final OfflineSendHandler _sender;
  var _running = false;

  /// Default conflict strategy.
  ConflictStrategy strategy;

  /// Custom resolver used when [strategy] is [ConflictStrategy.custom].
  ConflictResolver? resolver;

  final StreamController<SyncProgress> _progress =
      StreamController<SyncProgress>.broadcast();

  /// Progress updates.
  Stream<SyncProgress> get onProgress => _progress.stream;

  /// Whether a drain is in flight.
  bool get isRunning => _running;

  /// Current counts.
  SyncProgress snapshot({bool? running}) {
    final items = _queue.items;
    return SyncProgress(
      queue: items.length,
      completed: items
          .where((item) => item.status == OfflineQueueStatus.success)
          .length,
      processing: items
          .where((item) => item.status == OfflineQueueStatus.processing)
          .length,
      pending: items
          .where(
            (item) =>
                item.status == OfflineQueueStatus.pending ||
                item.status == OfflineQueueStatus.retrying,
          )
          .length,
      failed: items
          .where((item) => item.status == OfflineQueueStatus.failed)
          .length,
      cancelled: items
          .where((item) => item.status == OfflineQueueStatus.cancelled)
          .length,
      needsResolution: items
          .where((item) => item.status == OfflineQueueStatus.needsResolution)
          .length,
      running: running ?? _running,
    );
  }

  /// Sends pending entries one at a time.
  Future<SyncProgress> synchronize() async {
    if (_running) {
      return snapshot();
    }
    _running = true;
    _emit();
    try {
      while (true) {
        final item = _queue.nextWorkItem();
        if (item == null) {
          break;
        }
        await _process(item);
        _emit();
      }
    } finally {
      _running = false;
      _emit();
    }
    return snapshot();
  }

  Future<void> _process(OfflineQueuedRequest item) async {
    await _queue.update(
      item.id,
      status: OfflineQueueStatus.processing,
      attempts: item.attempts + 1,
    );
    try {
      final result = await _sender(item);
      if (result.statusCode == 409) {
        await _resolveConflict(item, result.body);
        return;
      }
      if (result.statusCode >= 200 && result.statusCode < 300) {
        await _queue.update(item.id, status: OfflineQueueStatus.success);
        return;
      }
      if (result.statusCode >= 500 || result.statusCode == 429) {
        await _queue.update(
          item.id,
          status: OfflineQueueStatus.retrying,
          lastError: 'HTTP ${result.statusCode}',
        );
        return;
      }
      await _queue.update(
        item.id,
        status: OfflineQueueStatus.failed,
        lastError: 'HTTP ${result.statusCode}',
      );
    } on FlutterGuardException catch (error) {
      await _queue.update(
        item.id,
        status: OfflineQueueStatus.retrying,
        lastError: error.message,
      );
    } catch (error) {
      await _queue.update(
        item.id,
        status: OfflineQueueStatus.failed,
        lastError: error.toString(),
      );
    }
  }

  Future<void> _resolveConflict(
    OfflineQueuedRequest item,
    Object? serverPayload,
  ) async {
    final context = ConflictContext(
      clientPayload: item.data,
      serverPayload: serverPayload,
      clientUpdatedAt: item.clientUpdatedAt ?? item.createdAt,
      serverUpdatedAt: _readTimestamp(serverPayload),
      path: item.path,
    );

    switch (strategy) {
      case ConflictStrategy.serverWins:
        await _queue.update(item.id, status: OfflineQueueStatus.success);
      case ConflictStrategy.clientWins:
        await _resend(item, item.data);
      case ConflictStrategy.lastWriteWins:
        final clientTime =
            context.clientUpdatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final serverTime =
            context.serverUpdatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        if (clientTime.isAfter(serverTime)) {
          await _resend(item, item.data);
        } else {
          await _queue.update(item.id, status: OfflineQueueStatus.success);
        }
      case ConflictStrategy.custom:
        final resolved = await (resolver ?? _defaultResolver)(context);
        await _resend(item, resolved);
      case ConflictStrategy.manual:
        await _queue.update(
          item.id,
          status: OfflineQueueStatus.needsResolution,
          lastError: 'Conflict requires manual resolution',
        );
    }
  }

  Future<void> _resend(OfflineQueuedRequest item, Object? data) async {
    final result = await _sender(item, overrideData: data);
    if (result.statusCode >= 200 && result.statusCode < 300) {
      await _queue.update(item.id, status: OfflineQueueStatus.success);
    } else {
      await _queue.update(
        item.id,
        status: OfflineQueueStatus.failed,
        lastError: 'Conflict rewrite failed HTTP ${result.statusCode}',
      );
    }
  }

  Future<Object?> _defaultResolver(ConflictContext context) async {
    return context.serverPayload ?? context.clientPayload;
  }

  DateTime? _readTimestamp(Object? payload) {
    if (payload is Map) {
      final raw = payload['updatedAt'] ?? payload['updated_at'];
      if (raw is String) {
        return DateTime.tryParse(raw);
      }
    }
    if (payload is String) {
      try {
        return _readTimestamp(jsonDecode(payload));
      } on Object {
        return null;
      }
    }
    return null;
  }

  void _emit() {
    if (!_progress.isClosed) {
      _progress.add(snapshot());
    }
  }

  /// Closes progress streams.
  Future<void> dispose() => _progress.close();
}
