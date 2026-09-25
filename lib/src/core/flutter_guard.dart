import 'dart:async';

import '../auth/guard_auth.dart';
import '../cache/guard_cache.dart';
import '../connectivity/connectivity_adapter.dart';
import '../connectivity/connectivity_monitor.dart';
import '../connectivity/connectivity_status.dart';
import '../diagnostics/guard_diagnostics.dart';
import '../diagnostics/logging/guard_logger.dart';
import '../diagnostics/metrics/guard_metrics.dart';
import '../feature_flags/feature_flags.dart';
import '../network/client/guard_network.dart';
import '../network/transport/guard_transport.dart';
import '../network/transport/http_transport.dart';
import '../offline/guard_offline.dart';
import '../offline/queue/offline_queue.dart';
import '../offline/sync/guard_sync.dart';
import '../storage/key_value_store.dart';
import 'capabilities/guard_capabilities.dart';
import 'config/flutter_guard_config.dart';
import 'environment/guard_environment.dart';
import 'exceptions/exceptions.dart';
import 'lifecycle/app_lifecycle_monitor.dart';

/// Production infrastructure entry point.
///
/// ```dart
/// await FlutterGuard.initialize(
///   FlutterGuardConfig(baseUrl: 'https://api.example.com'),
/// );
/// final response = await FlutterGuard.instance.network.get('/health');
/// ```
class FlutterGuard {
  FlutterGuard._(this.config);

  static FlutterGuard? _instance;

  /// Active singleton created by [initialize].
  ///
  /// Throws [UnknownException] when [initialize] has not been called.
  static FlutterGuard get instance {
    final value = _instance;
    if (value == null) {
      throw const UnknownException(
        'FlutterGuard.initialize must be called before FlutterGuard.instance',
      );
    }
    return value;
  }

  /// Whether [initialize] has completed.
  static bool get isInitialized => _instance != null;

  /// Initializes the process-wide singleton.
  ///
  /// Calling this again disposes the previous instance first.
  static Future<FlutterGuard> initialize(FlutterGuardConfig config) async {
    if (_instance != null) {
      await _instance!.dispose();
    }
    final guard = FlutterGuard._(config);
    await guard._start();
    _instance = guard;
    return guard;
  }

  /// Creates an isolated instance that does not replace [instance].
  ///
  /// Use this in tests or when more than one client is required.
  static Future<FlutterGuard> create(FlutterGuardConfig config) async {
    final guard = FlutterGuard._(config);
    await guard._start();
    return guard;
  }

  /// Disposes and forgets the singleton.
  static Future<void> reset() async {
    await _instance?.dispose();
    _instance = null;
  }

  /// Active configuration after environment presets are applied.
  final FlutterGuardConfig config;

  late final GuardKeyValueStore _store;
  late final GuardTransport _transport;

  /// Structured logger.
  late final GuardLogger logger;

  /// Request counters and samples.
  late final GuardMetrics metrics;

  /// Combined diagnostics facade.
  late final GuardDiagnostics diagnostics;

  /// Authentication and token refresh.
  late final GuardAuth auth;

  /// HTTP response cache.
  late final GuardCache cache;

  /// Connectivity adapter monitor.
  late final ConnectivityMonitor connectivity;
  late final OfflineQueue _queue;
  late final GuardSync _sync;

  /// Offline queue facade.
  late final GuardOffline offline;

  /// HTTP client.
  late final GuardNetwork network;

  /// Local feature flags.
  late final FeatureFlags flags;

  /// App lifecycle observer.
  late final AppLifecycleMonitor lifecycle;

  /// Runtime capability snapshot.
  late final GuardCapabilities capabilities;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  bool _ownsTransport = false;
  bool _ownsStore = false;

  /// Current environment.
  GuardEnvironment get environment => config.environment.environment;

  /// Offline synchronization engine.
  GuardSync get sync => _sync;

  /// Whether the inspector is allowed to open.
  bool get inspectorEnabled {
    if (!config.inspector.enabled) {
      return false;
    }
    if (!_isReleaseMode) {
      return true;
    }
    return config.inspector.allowInRelease;
  }

  Future<void> _start() async {
    _store = config.store ?? MemoryKeyValueStore();
    _ownsStore = config.store == null;
    _transport =
        config.transport ??
        HttpGuardTransport(
          followRedirects: config.network.followRedirects,
          maxRedirects: config.network.maxRedirects,
        );
    _ownsTransport = config.transport == null;

    logger = GuardLogger(config.diagnostics);
    metrics = GuardMetrics(config.diagnostics);
    diagnostics = GuardDiagnostics(
      config: config.diagnostics,
      logger: logger,
      metrics: metrics,
    );
    auth = GuardAuth(config: config.auth);
    cache = GuardCache(config: config.cache, store: _store);
    await cache.hydrate();

    connectivity = ConnectivityMonitor(
      adapter: config.connectivityAdapter ?? ManualConnectivityAdapter(),
      probeUri: config.baseUrl == null ? null : Uri.parse(config.baseUrl!),
    );
    await connectivity.start();

    _queue = OfflineQueue(config: config.offline, store: _store);
    await _queue.hydrate();
    metrics.offlineQueuePending = _queue.pendingCount;

    _sync = GuardSync(
      queue: _queue,
      sender: (item, {Object? overrideData}) async {
        try {
          final response = await network.send<Object>(
            item.method,
            item.path,
            query: item.query,
            headers: item.headers,
            data: overrideData ?? item.data,
            queueIfOffline: false,
            retry: false,
          );
          return (statusCode: response.statusCode, body: response.data);
        } on FlutterGuardException catch (error) {
          return (statusCode: error.statusCode ?? 0, body: error.message);
        }
      },
    );
    offline = GuardOffline(config: config.offline, queue: _queue, sync: _sync);

    network = GuardNetwork(
      config: config,
      transport: _transport,
      auth: auth,
      cache: cache,
      offline: offline,
      connectivity: connectivity,
      logger: logger,
      metrics: metrics,
    );

    flags = FeatureFlags(config: config.featureFlags, environment: environment);
    await flags.reload();

    lifecycle = AppLifecycleMonitor();
    try {
      lifecycle.attach();
    } on Object {
      // Tests without a binding can still construct FlutterGuard.
    }

    capabilities = GuardCapabilities(
      persistentCache: config.cache.persistent,
      persistentQueue: config.offline.persistentQueue,
      inspector: inspectorEnabled,
      diagnostics: config.diagnostics.enabled,
      customTransport: !_ownsTransport,
      customStore: !_ownsStore,
    );

    _connectivitySubscription = connectivity.onChange.listen((status) {
      metrics.offlineQueuePending = _queue.pendingCount;
      if (status == ConnectivityStatus.online &&
          config.offline.enabled &&
          config.offline.autoSync) {
        unawaited(_sync.synchronize());
      }
    });

    logger.info(
      'FlutterGuard initialized',
      metadata: <String, Object?>{
        'environment': environment.name,
        'baseUrl': config.baseUrl,
      },
    );
  }

  /// Releases streams, observers, and the default transport.
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    await _sync.dispose();
    await _queue.dispose();
    await connectivity.dispose();
    await lifecycle.dispose();
    if (_ownsTransport) {
      await _transport.close();
    }
    if (_instance == this) {
      _instance = null;
    }
  }

  bool get _isReleaseMode {
    var release = true;
    assert(() {
      release = false;
      return true;
    }());
    return release;
  }
}
