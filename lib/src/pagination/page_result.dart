/// One page of results returned by a pagination fetch function.
class PageResult<T> {
  /// Creates a page.
  const PageResult({
    required this.items,
    this.hasMore = false,
    this.nextCursor,
    this.total,
  });

  /// Items in this page.
  final List<T> items;

  /// Whether another page exists.
  final bool hasMore;

  /// Cursor for the next page, when using cursor pagination.
  final String? nextCursor;

  /// Optional total count advertised by the API.
  final int? total;
}
