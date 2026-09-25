import 'package:flutter/material.dart';
import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import '../../shared/widgets.dart';

class PaginationPage extends StatefulWidget {
  const PaginationPage({super.key});

  @override
  State<PaginationPage> createState() => _PaginationPageState();
}

class _PaginationPageState extends State<PaginationPage> {
  late final Paginator<String> _page;
  late final Paginator<String> _offset;
  late final Paginator<String> _cursor;

  @override
  void initState() {
    super.initState();
    final guard = FlutterGuard.instance;
    _page = Paginator<String>.page(
      fetch: (page, size) async {
        final response = await guard.network.get<Map<String, Object?>>(
          '/items',
          query: <String, Object?>{
            'mode': 'page',
            'page': page,
            'pageSize': size,
          },
          parser: (json) => Map<String, Object?>.from(json! as Map),
        );
        return _toPage(response.data!);
      },
    );
    _offset = Paginator<String>.offset(
      fetch: (offset, limit) async {
        final response = await guard.network.get<Map<String, Object?>>(
          '/items',
          query: <String, Object?>{
            'mode': 'offset',
            'offset': offset,
            'limit': limit,
          },
          parser: (json) => Map<String, Object?>.from(json! as Map),
        );
        return _toPage(response.data!);
      },
    );
    _cursor = Paginator<String>.cursor(
      fetch: (cursor, limit) async {
        final response = await guard.network.get<Map<String, Object?>>(
          '/items',
          query: <String, Object?>{
            'mode': 'cursor',
            'cursor': cursor,
            'limit': limit,
          },
          parser: (json) => Map<String, Object?>.from(json! as Map),
        );
        return _toPage(response.data!);
      },
    );
  }

  PageResult<String> _toPage(Map<String, Object?> json) {
    return PageResult<String>(
      items: (json['items']! as List<dynamic>).cast<String>(),
      hasMore: json['hasMore'] as bool? ?? false,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  @override
  void dispose() {
    _page.dispose();
    _offset.dispose();
    _cursor.dispose();
    super.dispose();
  }

  Widget _paginator(String title, Paginator<String> paginator) {
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'items ${paginator.items}\n'
            'page ${paginator.currentPage} hasMore ${paginator.hasMore}\n'
            'loading ${paginator.isLoading} loadingMore ${paginator.isLoadingMore}\n'
            'error ${paginator.error?.message ?? 'none'}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () async {
                  await paginator.load();
                  setState(() {});
                },
                child: const Text('Load'),
              ),
              FilledButton(
                onPressed: () async {
                  await paginator.loadMore();
                  await paginator.loadMore();
                  setState(() {});
                },
                child: const Text('Load more x2'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await paginator.refresh();
                  setState(() {});
                },
                child: const Text('Refresh'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await paginator.retry();
                  setState(() {});
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Pagination',
      child: Column(
        children: [
          _paginator('Page-based', _page),
          _paginator('Offset-based', _offset),
          _paginator('Cursor-based', _cursor),
        ],
      ),
    );
  }
}
