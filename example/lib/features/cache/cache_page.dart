import 'package:flutter/material.dart';
import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import '../../shared/widgets.dart';

class CachePage extends StatefulWidget {
  const CachePage({super.key});

  @override
  State<CachePage> createState() => _CachePageState();
}

class _CachePageState extends State<CachePage> {
  String _output = 'Run a policy to see hit/miss and network behavior.';
  String? _swrFresh;

  FlutterGuard get guard => FlutterGuardScope.of(context);

  Future<void> _policy(CachePolicy policy) async {
    try {
      final response = await guard.network.get<Object>(
        '/products',
        cachePolicy: policy,
        cacheTags: const <String>['products'],
      );
      setState(() {
        _output =
            'Policy ${policy.name}\n'
            'hits ${guard.metrics.cacheHits} misses ${guard.metrics.cacheMisses}\n'
            '${describeResponse(response)}';
      });
    } catch (error) {
      setState(() => _output = describeError(error));
    }
  }

  Future<void> _swr() async {
    _swrFresh = null;
    final first = await guard.network.get<Object>(
      '/products',
      cachePolicy: CachePolicy.staleWhileRevalidate,
      cacheTags: const <String>['products'],
      onRevalidate: (fresh) {
        setState(() => _swrFresh = describeResponse(fresh));
      },
    );
    setState(() {
      _output =
          'Cached/stale response shown immediately:\n${describeResponse(first)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Cache',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(message: _output),
          if (_swrFresh != null)
            StatusBanner(message: 'Background refresh:\n$_swrFresh'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final policy in CachePolicy.values)
                FilledButton(
                  onPressed: () => _policy(policy),
                  child: Text(policy.name),
                ),
              FilledButton(onPressed: _swr, child: const Text('SWR flow')),
              OutlinedButton(
                onPressed: () async {
                  await guard.cache.invalidate('/products');
                  setState(() => _output = 'Invalidated URL /products');
                },
                child: const Text('Invalidate URL'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await guard.cache.invalidateTag('products');
                  setState(() => _output = 'Invalidated tag products');
                },
                child: const Text('Invalidate tag'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await guard.cache.clear();
                  setState(() => _output = 'Cache cleared');
                },
                child: const Text('Clear cache'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Entries: ${guard.cache.entries.map((e) => e.key).join(', ')}'),
        ],
      ),
    );
  }
}
