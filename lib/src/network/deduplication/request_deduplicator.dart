import 'dart:convert';

import '../request/guard_request.dart';
import '../response/api_response.dart';

/// Shares one in-flight request among identical callers.
class RequestDeduplicator {
  final Map<String, Future<ApiResponse<dynamic>>> _inFlight =
      <String, Future<ApiResponse<dynamic>>>{};

  /// Number of requests currently sharing a transport call.
  int get inFlightCount => _inFlight.length;

  /// Number of callers that joined an existing in-flight request.
  int joins = 0;

  /// Builds a stable key for [request].
  String keyFor(GuardRequest request) {
    final query = request.query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final headers =
        request.headers.entries
            .where((entry) => !_ignoredHeader(entry.key))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return jsonEncode(<String, Object?>{
      'method': request.method,
      'url': request.url.toString(),
      'query': <String, String>{for (final e in query) e.key: e.value},
      'headers': <String, String>{for (final e in headers) e.key: e.value},
      'data': request.data,
      'multipart': request.multipart == null
          ? null
          : <String, Object?>{
              'fields': request.multipart!.fields,
              'files': request.multipart!.files
                  .map(
                    (file) =>
                        '${file.field}:${file.filename}:${file.bytes.length}',
                  )
                  .toList(),
            },
    });
  }

  /// Joins an in-flight call or starts [run].
  Future<ApiResponse<T>> join<T>(
    String key,
    Future<ApiResponse<T>> Function() run,
  ) {
    final existing = _inFlight[key];
    if (existing != null) {
      joins += 1;
      return existing.then((response) => response as ApiResponse<T>);
    }
    final future = run();
    _inFlight[key] = future.then<ApiResponse<dynamic>>((response) => response);
    return future.whenComplete(() {
      _inFlight.remove(key);
    });
  }

  bool _ignoredHeader(String name) {
    final lower = name.toLowerCase();
    return lower == 'authorization' ||
        lower == 'cookie' ||
        lower == 'x-request-id';
  }
}
