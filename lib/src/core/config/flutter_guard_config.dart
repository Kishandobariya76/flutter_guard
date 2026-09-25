import '../../connectivity/connectivity_adapter.dart';
import '../../diagnostics/logging/log_level.dart';
import '../../network/transport/guard_transport.dart';
import '../../storage/key_value_store.dart';
import '../environment/guard_environment.dart';
import 'auth_config.dart';
import 'cache_config.dart';
import 'diagnostics_config.dart';
import 'environment_config.dart';
import 'feature_flag_config.dart';
import 'inspector_config.dart';
import 'network_config.dart';
import 'offline_config.dart';

/// Root configuration passed to [FlutterGuard.initialize].
///
/// ```dart
/// await FlutterGuard.initialize(
///   FlutterGuardConfig(
///     baseUrl: 'https://api.example.com',
///     network: NetworkConfig(
///       connectTimeout: Duration(seconds: 15),
///       receiveTimeout: Duration(seconds: 30),
///     ),
///   ),
/// );
/// ```
class FlutterGuardConfig {
  /// Creates a configuration.
  ///
  /// When [environment.applyPresets] is true, logging and inspector defaults
  /// are adjusted for the selected environment unless you pass explicit
  /// [diagnostics] or [inspector] instances that already encode those choices.
  factory FlutterGuardConfig({
    String? baseUrl,
    NetworkConfig network = const NetworkConfig(),
    AuthConfig auth = const AuthConfig(),
    CacheConfig cache = const CacheConfig(),
    OfflineConfig offline = const OfflineConfig(),
    DiagnosticsConfig diagnostics = const DiagnosticsConfig(),
    InspectorConfig inspector = const InspectorConfig(),
    FeatureFlagConfig featureFlags = const FeatureFlagConfig(),
    EnvironmentConfig environment = const EnvironmentConfig(),
    GuardTransport? transport,
    GuardKeyValueStore? store,
    ConnectivityAdapter? connectivityAdapter,
  }) {
    var resolvedDiagnostics = diagnostics;
    var resolvedInspector = inspector;
    if (environment.applyPresets) {
      resolvedDiagnostics = _presetDiagnostics(
        environment.environment,
        diagnostics,
      );
      resolvedInspector = _presetInspector(environment.environment, inspector);
    }
    return FlutterGuardConfig._(
      baseUrl: _normalizeBaseUrl(baseUrl),
      network: network,
      auth: auth,
      cache: cache,
      offline: offline,
      diagnostics: resolvedDiagnostics,
      inspector: resolvedInspector,
      featureFlags: featureFlags,
      environment: environment,
      transport: transport,
      store: store,
      connectivityAdapter: connectivityAdapter,
    );
  }

  const FlutterGuardConfig._({
    required this.baseUrl,
    required this.network,
    required this.auth,
    required this.cache,
    required this.offline,
    required this.diagnostics,
    required this.inspector,
    required this.featureFlags,
    required this.environment,
    required this.transport,
    required this.store,
    required this.connectivityAdapter,
  });

  /// Root URL prepended to relative request paths.
  ///
  /// **Type:** `String?`
  /// **Required:** no
  /// **Default:** `null`
  /// **Purpose:** Lets callers pass `/users/1` instead of an absolute URL.
  /// **Allowed values:** A URL without a trailing slash, or `null`.
  /// **Example:** `FlutterGuardConfig(baseUrl: 'https://api.example.com')`
  /// **Production recommendation:** Use `--dart-define` per environment.
  /// **Common mistakes:** Putting a path suffix such as `/v1/` and then also
  /// passing `/v1` on every call.
  final String? baseUrl;

  /// HTTP client settings.
  ///
  /// **Type:** [NetworkConfig]
  /// **Required:** no
  /// **Default:** [NetworkConfig.defaults]
  /// **Purpose:** Timeouts, retries, and default headers.
  /// **Allowed values:** Any [NetworkConfig].
  /// **Example:** `FlutterGuardConfig(network: NetworkConfig())`
  /// **Production recommendation:** Set timeouts from real API SLAs.
  /// **Common mistakes:** Leaving development timeouts in production.
  final NetworkConfig network;

  /// Authentication settings.
  ///
  /// **Type:** [AuthConfig]
  /// **Required:** no
  /// **Default:** [AuthConfig.defaults]
  /// **Purpose:** Token attachment and refresh.
  /// **Allowed values:** Any [AuthConfig].
  /// **Example:** `FlutterGuardConfig(auth: AuthConfig())`
  /// **Production recommendation:** Inject a secure [TokenStore].
  /// **Common mistakes:** Hard-coding production tokens.
  final AuthConfig auth;

  /// Cache settings.
  ///
  /// **Type:** [CacheConfig]
  /// **Required:** no
  /// **Default:** [CacheConfig.defaults]
  /// **Purpose:** Memory/persistent cache and default policy.
  /// **Allowed values:** Any [CacheConfig].
  /// **Example:** `FlutterGuardConfig(cache: CacheConfig(enabled: true))`
  /// **Production recommendation:** Do not persist sensitive payloads unless
  /// the store encrypts them.
  /// **Common mistakes:** Using `cacheOnly` as the global default.
  final CacheConfig cache;

  /// Offline queue settings.
  ///
  /// **Type:** [OfflineConfig]
  /// **Required:** no
  /// **Default:** [OfflineConfig.defaults]
  /// **Purpose:** Queues writes while offline.
  /// **Allowed values:** Any [OfflineConfig].
  /// **Example:** `FlutterGuardConfig(offline: OfflineConfig(enabled: true))`
  /// **Production recommendation:** Enable persistence for unfinished writes.
  /// **Common mistakes:** Queuing requests that contain secrets.
  final OfflineConfig offline;

  /// Diagnostics settings after environment presets are applied.
  ///
  /// **Type:** [DiagnosticsConfig]
  /// **Required:** no
  /// **Default:** environment-dependent
  /// **Purpose:** Logging, redaction, and metrics.
  /// **Allowed values:** Any [DiagnosticsConfig].
  /// **Example:** `FlutterGuardConfig(diagnostics: DiagnosticsConfig())`
  /// **Production recommendation:** Keep redaction enabled.
  /// **Common mistakes:** Shipping debug logs to production.
  final DiagnosticsConfig diagnostics;

  /// Inspector settings after environment presets are applied.
  ///
  /// **Type:** [InspectorConfig]
  /// **Required:** no
  /// **Default:** environment-dependent
  /// **Purpose:** Gates the debug inspector.
  /// **Allowed values:** Any [InspectorConfig].
  /// **Example:** `FlutterGuardConfig(inspector: InspectorConfig(enabled: true))`
  /// **Production recommendation:** Disable in production.
  /// **Common mistakes:** Enabling [InspectorConfig.allowInRelease].
  final InspectorConfig inspector;

  /// Feature-flag settings.
  ///
  /// **Type:** [FeatureFlagConfig]
  /// **Required:** no
  /// **Default:** [FeatureFlagConfig.defaults]
  /// **Purpose:** Local flags and rollout targeting.
  /// **Allowed values:** Any [FeatureFlagConfig].
  /// **Example:** `FlutterGuardConfig(featureFlags: FeatureFlagConfig())`
  /// **Production recommendation:** Use conservative defaults.
  /// **Common mistakes:** Expecting a remote fetch in V1.
  final FeatureFlagConfig featureFlags;

  /// Environment name and preset switch.
  ///
  /// **Type:** [EnvironmentConfig]
  /// **Required:** no
  /// **Default:** [EnvironmentConfig.defaults]
  /// **Purpose:** Selects development, staging, or production behavior.
  /// **Allowed values:** Any [EnvironmentConfig].
  /// **Example:** `FlutterGuardConfig(environment: EnvironmentConfig())`
  /// **Production recommendation:** Drive this from build configuration.
  /// **Common mistakes:** Leaving the development preset in a store build.
  final EnvironmentConfig environment;

  /// Replaceable HTTP transport.
  ///
  /// **Type:** [GuardTransport]?
  /// **Required:** no
  /// **Default:** [HttpGuardTransport]
  /// **Purpose:** Swap `package:http` for a test double or another client.
  /// **Allowed values:** Any [GuardTransport].
  /// **Example:** `FlutterGuardConfig(transport: DemoTransport())`
  /// **Production recommendation:** Use the default unless you already own a
  /// client.
  /// **Common mistakes:** Injecting a transport that ignores cancellation.
  final GuardTransport? transport;

  /// Shared key-value store for cache, queue, and local flags.
  ///
  /// **Type:** [GuardKeyValueStore]?
  /// **Required:** no
  /// **Default:** [MemoryKeyValueStore]
  /// **Purpose:** Persistence port. File and secure adapters are injected here.
  /// **Allowed values:** Any [GuardKeyValueStore].
  /// **Example:** `FlutterGuardConfig(store: MemoryKeyValueStore())`
  /// **Production recommendation:** Inject an encrypted store for tokens and
  /// personal data.
  /// **Common mistakes:** Assuming the default store survives process death.
  final GuardKeyValueStore? store;

  /// Connectivity source.
  ///
  /// **Type:** [ConnectivityAdapter]?
  /// **Required:** no
  /// **Default:** [ManualConnectivityAdapter] starting online, or a probe
  /// adapter when [baseUrl] is set.
  /// **Purpose:** Lets tests and the example simulate offline.
  /// **Allowed values:** Any [ConnectivityAdapter].
  /// **Example:** `FlutterGuardConfig(connectivityAdapter: ManualConnectivityAdapter())`
  /// **Production recommendation:** Inject a platform adapter if you already
  /// use one.
  /// **Common mistakes:** Treating connectivity as proof of internet
  /// reachability.
  final ConnectivityAdapter? connectivityAdapter;

  static String? _normalizeBaseUrl(String? value) {
    if (value == null) {
      return null;
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static DiagnosticsConfig _presetDiagnostics(
    GuardEnvironment environment,
    DiagnosticsConfig incoming,
  ) {
    if (incoming != const DiagnosticsConfig()) {
      return incoming;
    }
    return switch (environment) {
      GuardEnvironment.development => const DiagnosticsConfig(
        logLevel: LogLevel.debug,
      ),
      GuardEnvironment.staging => const DiagnosticsConfig(
        logLevel: LogLevel.info,
      ),
      GuardEnvironment.production => const DiagnosticsConfig(
        logLevel: LogLevel.error,
      ),
    };
  }

  static InspectorConfig _presetInspector(
    GuardEnvironment environment,
    InspectorConfig incoming,
  ) {
    if (incoming != const InspectorConfig()) {
      return incoming;
    }
    return switch (environment) {
      GuardEnvironment.development ||
      GuardEnvironment.staging => const InspectorConfig(enabled: true),
      GuardEnvironment.production => const InspectorConfig(enabled: false),
    };
  }
}
