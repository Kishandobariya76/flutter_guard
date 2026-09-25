import 'dart:async';

import '../core/exceptions/exceptions.dart';
import 'page_result.dart';

/// Pagination style.
enum PaginationMode {
  /// `?page=&pageSize=`.
  page,

  /// `?offset=&limit=`.
  offset,

  /// `?cursor=`.
  cursor,
}

/// In-memory paginator with duplicate-request protection.
class Paginator<T> {
  Paginator._({
    required this.mode,
    required this.pageSize,
    required Future<PageResult<T>> Function(PaginatorState state) fetch,
  }) : _fetch = fetch;

  /// Page-based paginator. [page] starts at 1.
  factory Paginator.page({
    required Future<PageResult<T>> Function(int page, int pageSize) fetch,
    int pageSize = 20,
  }) {
    return Paginator._(
      mode: PaginationMode.page,
      pageSize: pageSize,
      fetch: (state) => fetch(state.page, pageSize),
    );
  }

  /// Offset-based paginator.
  factory Paginator.offset({
    required Future<PageResult<T>> Function(int offset, int limit) fetch,
    int pageSize = 20,
  }) {
    return Paginator._(
      mode: PaginationMode.offset,
      pageSize: pageSize,
      fetch: (state) => fetch(state.offset, pageSize),
    );
  }

  /// Cursor-based paginator.
  factory Paginator.cursor({
    required Future<PageResult<T>> Function(String? cursor, int limit) fetch,
    int pageSize = 20,
  }) {
    return Paginator._(
      mode: PaginationMode.cursor,
      pageSize: pageSize,
      fetch: (state) => fetch(state.cursor, pageSize),
    );
  }

  /// Active mode.
  final PaginationMode mode;

  /// Page size / limit.
  final int pageSize;

  final Future<PageResult<T>> Function(PaginatorState state) _fetch;
  final List<T> _items = <T>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  int _page = 1;
  int _offset = 0;
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadingMore = false;
  FlutterGuardException? _error;

  /// Loaded items.
  List<T> get items => List<T>.unmodifiable(_items);

  /// 1-based page for page mode.
  int get currentPage => _page;

  /// Whether another page is available.
  bool get hasMore => _hasMore;

  /// Initial load in flight.
  bool get isLoading => _loading;

  /// Subsequent page in flight.
  bool get isLoadingMore => _loadingMore;

  /// Last error, if any.
  FlutterGuardException? get error => _error;

  /// Emits after each state change.
  Stream<void> get onChange => _changes.stream;

  /// Loads the first page, replacing current items.
  Future<void> load() async {
    if (_loading) {
      return;
    }
    _loading = true;
    _error = null;
    _page = 1;
    _offset = 0;
    _cursor = null;
    _emit();
    try {
      final result = await _fetch(
        PaginatorState(page: 1, offset: 0, cursor: null),
      );
      _items
        ..clear()
        ..addAll(result.items);
      _hasMore = result.hasMore;
      _cursor = result.nextCursor;
      _page = 1;
      _offset = _items.length;
    } on FlutterGuardException catch (error) {
      _error = error;
    } catch (error) {
      _error = UnknownException('Pagination load failed', cause: error);
    } finally {
      _loading = false;
      _emit();
    }
  }

  /// Loads the next page. Duplicate calls while in flight are ignored.
  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) {
      return;
    }
    _loadingMore = true;
    _error = null;
    _emit();
    try {
      final nextPage = _page + 1;
      final result = await _fetch(
        PaginatorState(page: nextPage, offset: _offset, cursor: _cursor),
      );
      _items.addAll(result.items);
      _hasMore = result.hasMore;
      _cursor = result.nextCursor;
      _page = nextPage;
      _offset = _items.length;
    } on FlutterGuardException catch (error) {
      _error = error;
    } catch (error) {
      _error = UnknownException('Pagination loadMore failed', cause: error);
    } finally {
      _loadingMore = false;
      _emit();
    }
  }

  /// Reloads from the first page.
  Future<void> refresh() => load();

  /// Retries after an error. Uses [load] when the list is empty.
  Future<void> retry() {
    if (_items.isEmpty) {
      return load();
    }
    return loadMore();
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  /// Closes the change stream.
  Future<void> dispose() => _changes.close();
}

/// Values passed to a pagination fetch function.
class PaginatorState {
  /// Creates state.
  const PaginatorState({
    required this.page,
    required this.offset,
    required this.cursor,
  });

  /// 1-based page.
  final int page;

  /// Offset in items.
  final int offset;

  /// Cursor from the previous page.
  final String? cursor;
}
