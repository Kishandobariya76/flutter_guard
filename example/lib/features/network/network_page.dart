import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

import '../../core/demo_bootstrap.dart';
import '../../shared/widgets.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  String _output = 'Run a request to see ApiResponse fields.';
  bool _error = false;

  FlutterGuard get guard => FlutterGuardScope.of(context);

  Future<void> _run(Future<ApiResponse<dynamic>> Function() action) async {
    setState(() {
      _error = false;
      _output = 'Loading…';
    });
    try {
      final response = await action();
      setState(() => _output = describeResponse(response));
    } catch (error) {
      setState(() {
        _error = true;
        _output = describeError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Network',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(message: _output, error: _error),
          SectionCard(
            title: 'HTTP methods',
            subtitle: 'Each button calls GuardNetwork, not a fake helper.',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _run(
                    () => guard.network.get<Map<String, Object?>>(
                      '/users/123',
                      parser: (json) => Map<String, Object?>.from(json! as Map),
                    ),
                  ),
                  child: const Text('GET'),
                ),
                FilledButton(
                  onPressed: () => _run(
                    () => guard.network.post<Map<String, Object?>>(
                      '/orders',
                      data: <String, Object?>{'item': 'book'},
                      parser: (json) => Map<String, Object?>.from(json! as Map),
                    ),
                  ),
                  child: const Text('POST'),
                ),
                FilledButton(
                  onPressed: () => _run(
                    () => guard.network.put<Object>(
                      '/users/123',
                      data: <String, Object?>{'name': 'Ada'},
                    ),
                  ),
                  child: const Text('PUT'),
                ),
                FilledButton(
                  onPressed: () => _run(
                    () => guard.network.patch<Object>(
                      '/users/123',
                      data: <String, Object?>{'name': 'Grace'},
                    ),
                  ),
                  child: const Text('PATCH'),
                ),
                FilledButton(
                  onPressed: () =>
                      _run(() => guard.network.delete<Object>('/users/123')),
                  child: const Text('DELETE'),
                ),
                FilledButton(
                  onPressed: () =>
                      _run(() => guard.network.head<Object>('/health')),
                  child: const Text('HEAD'),
                ),
                FilledButton(
                  onPressed: () => _run(
                    () => guard.network.send<Object>('OPTIONS', '/users/123'),
                  ),
                  child: const Text('OPTIONS'),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Query, headers, JSON, upload, download',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _run(
                    () => guard.network.get<Object>(
                      '/search',
                      query: <String, Object?>{'q': 'flutter'},
                      headers: <String, String>{'x-demo': '1'},
                    ),
                  ),
                  child: const Text('Query + headers'),
                ),
                OutlinedButton(
                  onPressed: () => _run(
                    () => guard.network.upload<Object>(
                      '/upload',
                      multipart: GuardMultipart(
                        fields: const <String, String>{'name': 'report'},
                        files: <GuardMultipartFile>[
                          GuardMultipartFile(
                            field: 'file',
                            filename: 'report.txt',
                            bytes: utf8.encode('demo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: const Text('Multipart upload'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _run(() => guard.network.download('/files/report.txt')),
                  child: const Text('Download'),
                ),
                OutlinedButton(
                  onPressed: () => _run(
                    () => guard.network.get<Object>(
                      '/timeout',
                      timeout: const Duration(milliseconds: 20),
                    ),
                  ),
                  child: const Text('Timeout'),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Typed errors',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in <int>[401, 403, 404, 422, 429, 500])
                  OutlinedButton(
                    onPressed: () =>
                        _run(() => guard.network.get<Object>('/errors/$code')),
                    child: Text('$code'),
                  ),
              ],
            ),
          ),
          Text('Transport calls: ${demoTransport.calls}'),
        ],
      ),
    );
  }
}
