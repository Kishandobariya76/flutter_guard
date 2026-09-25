import 'dart:convert';

import 'package:flutter_guard/flutter_guard.dart';

/// Test transport that records calls and runs a scripted handler.
class ScriptedTransport implements GuardTransport {
  /// Optional per-request handler.
  Future<GuardRawResponse> Function(GuardRequest request)? handler;

  /// Number of [send] invocations.
  int calls = 0;

  /// Recorded requests.
  final List<GuardRequest> requests = <GuardRequest>[];

  @override
  Future<GuardRawResponse> send(GuardRequest request) async {
    calls += 1;
    requests.add(request);
    request.cancelToken?.throwIfCancelled(requestId: request.requestId);
    if (handler != null) {
      return handler!(request);
    }
    return jsonResponse(request, <String, Object?>{'ok': true});
  }

  @override
  Future<void> close() async {}

  /// Builds a JSON response.
  static GuardRawResponse jsonResponse(
    GuardRequest request,
    Object? body, {
    int statusCode = 200,
    Map<String, String> headers = const <String, String>{},
  }) {
    return GuardRawResponse(
      statusCode: statusCode,
      headers: <String, String>{'content-type': 'application/json', ...headers},
      bodyBytes: utf8.encode(jsonEncode(body)),
      requestId: request.requestId,
    );
  }
}

/// Starts an isolated [FlutterGuard] with a [ScriptedTransport].
Future<(FlutterGuard, ScriptedTransport)> createGuard({
  FlutterGuardConfig Function(ScriptedTransport transport)? configure,
  AuthConfig? auth,
  CacheConfig cache = const CacheConfig(),
  OfflineConfig offline = const OfflineConfig(autoSync: false),
  ConnectivityAdapter? connectivity,
}) async {
  final transport = ScriptedTransport();
  final adapter = connectivity ?? ManualConnectivityAdapter();
  final config =
      configure?.call(transport) ??
      FlutterGuardConfig(
        baseUrl: 'https://api.example.com',
        transport: transport,
        auth: auth ?? const AuthConfig(),
        cache: cache,
        offline: offline,
        connectivityAdapter: adapter,
        environment: const EnvironmentConfig(applyPresets: false),
        diagnostics: const DiagnosticsConfig(logLevel: LogLevel.debug),
        inspector: const InspectorConfig(enabled: true),
      );
  final guard = await FlutterGuard.create(config);
  return (guard, transport);
}
