/// One documented configuration option used by the example playground and
/// by tests that keep the README table honest.
class ConfigOption {
  /// Creates a catalog entry.
  const ConfigOption({
    required this.owner,
    required this.name,
    required this.type,
    required this.defaultValue,
    required this.description,
    this.required = false,
  });

  /// Configuration class that owns the option.
  final String owner;

  /// Field name.
  final String name;

  /// Dart type shown to developers.
  final String type;

  /// Default value as a display string.
  final String defaultValue;

  /// Short purpose.
  final String description;

  /// Whether the caller must supply a value.
  final bool required;

  /// Qualified name such as `RetryConfig.maxAttempts`.
  String get qualified => '$owner.$name';
}

/// Complete catalog of public configuration options.
class ConfigCatalog {
  /// All public options.
  static const List<ConfigOption> options = <ConfigOption>[
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'baseUrl',
      type: 'String?',
      defaultValue: 'null',
      description: 'Root URL prepended to relative request paths.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'network',
      type: 'NetworkConfig',
      defaultValue: 'NetworkConfig.defaults',
      description: 'HTTP client settings.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'auth',
      type: 'AuthConfig',
      defaultValue: 'AuthConfig.defaults',
      description: 'Authentication and token-refresh settings.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'cache',
      type: 'CacheConfig',
      defaultValue: 'CacheConfig.defaults',
      description: 'In-memory and persistent cache settings.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'offline',
      type: 'OfflineConfig',
      defaultValue: 'OfflineConfig.defaults',
      description: 'Offline queue and synchronization settings.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'diagnostics',
      type: 'DiagnosticsConfig',
      defaultValue: 'environment-dependent',
      description: 'Logging, metrics, and redaction settings.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'inspector',
      type: 'InspectorConfig',
      defaultValue: 'environment-dependent',
      description: 'Debug inspector settings.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'featureFlags',
      type: 'FeatureFlagConfig',
      defaultValue: 'FeatureFlagConfig.defaults',
      description: 'Local feature-flag settings.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'environment',
      type: 'EnvironmentConfig',
      defaultValue: 'EnvironmentConfig.defaults',
      description: 'Environment name and preset switch.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'transport',
      type: 'GuardTransport?',
      defaultValue: 'HttpGuardTransport',
      description: 'Replaceable HTTP transport.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'store',
      type: 'GuardKeyValueStore?',
      defaultValue: 'MemoryKeyValueStore',
      description: 'Shared key-value store for cache, queue, and flags.',
    ),
    ConfigOption(
      owner: 'FlutterGuardConfig',
      name: 'connectivityAdapter',
      type: 'ConnectivityAdapter?',
      defaultValue: 'ManualConnectivityAdapter',
      description: 'Connectivity source.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'connectTimeout',
      type: 'Duration',
      defaultValue: '15s',
      description: 'Time allowed to establish a connection.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'receiveTimeout',
      type: 'Duration',
      defaultValue: '30s',
      description: 'Time allowed to receive the response body.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'sendTimeout',
      type: 'Duration',
      defaultValue: '30s',
      description: 'Time allowed to send the request body.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'retry',
      type: 'RetryConfig',
      defaultValue: 'RetryConfig.defaults',
      description: 'Default retry policy.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'defaultHeaders',
      type: 'Map<String, String>',
      defaultValue: '{}',
      description: 'Headers attached to every request.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'followRedirects',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the transport should follow HTTP redirects.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'maxRedirects',
      type: 'int',
      defaultValue: '5',
      description: 'Maximum number of redirects.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'enableDefaultDeduplication',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether identical in-flight requests are shared by default.',
    ),
    ConfigOption(
      owner: 'NetworkConfig',
      name: 'userAgent',
      type: 'String',
      defaultValue: 'flutter_guard_sdk/0.1.0',
      description: 'Default User-Agent header.',
    ),
    ConfigOption(
      owner: 'RetryConfig',
      name: 'maxAttempts',
      type: 'int',
      defaultValue: '3',
      description: 'Maximum number of attempts, including the first try.',
    ),
    ConfigOption(
      owner: 'RetryConfig',
      name: 'initialDelay',
      type: 'Duration',
      defaultValue: '500ms',
      description: 'Base delay before a retry.',
    ),
    ConfigOption(
      owner: 'RetryConfig',
      name: 'maxDelay',
      type: 'Duration',
      defaultValue: '10s',
      description: 'Upper bound for computed backoff delays.',
    ),
    ConfigOption(
      owner: 'RetryConfig',
      name: 'exponentialBackoff',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether each retry delay doubles, up to maxDelay.',
    ),
    ConfigOption(
      owner: 'RetryConfig',
      name: 'jitter',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether a random component is added to each delay.',
    ),
    ConfigOption(
      owner: 'RetryConfig',
      name: 'retryableStatusCodes',
      type: 'Set<int>',
      defaultValue: '{408, 429, 500, 502, 503, 504}',
      description: 'HTTP statuses that may be retried.',
    ),
    ConfigOption(
      owner: 'RetryConfig',
      name: 'retryNonIdempotent',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether POST and PATCH may be retried.',
    ),
    ConfigOption(
      owner: 'AuthConfig',
      name: 'accessTokenProvider',
      type: 'Future<String?> Function()?',
      defaultValue: 'null',
      description: 'Returns the current access token.',
    ),
    ConfigOption(
      owner: 'AuthConfig',
      name: 'refreshToken',
      type: 'Future<String?> Function()?',
      defaultValue: 'null',
      description: 'Exchanges a refresh token for a new access token.',
    ),
    ConfigOption(
      owner: 'AuthConfig',
      name: 'tokenStore',
      type: 'TokenStore?',
      defaultValue: 'MemoryTokenStore',
      description: 'Optional durable token store.',
    ),
    ConfigOption(
      owner: 'AuthConfig',
      name: 'refreshStatusCodes',
      type: 'Set<int>',
      defaultValue: '{401}',
      description: 'HTTP statuses that trigger a refresh-and-retry.',
    ),
    ConfigOption(
      owner: 'AuthConfig',
      name: 'attachAuthorization',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether FlutterGuard attaches the access token automatically.',
    ),
    ConfigOption(
      owner: 'AuthConfig',
      name: 'authorizationHeader',
      type: 'String',
      defaultValue: 'Authorization',
      description: 'Header that receives the access token.',
    ),
    ConfigOption(
      owner: 'AuthConfig',
      name: 'authorizationPrefix',
      type: 'String',
      defaultValue: 'Bearer ',
      description: 'Prefix written before the token.',
    ),
    ConfigOption(
      owner: 'AuthConfig',
      name: 'maxRefreshAttempts',
      type: 'int',
      defaultValue: '1',
      description: 'How many times a single request may trigger refresh.',
    ),
    ConfigOption(
      owner: 'CacheConfig',
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether caching is active.',
    ),
    ConfigOption(
      owner: 'CacheConfig',
      name: 'defaultTtl',
      type: 'Duration',
      defaultValue: '10 minutes',
      description: 'How long a written entry stays fresh.',
    ),
    ConfigOption(
      owner: 'CacheConfig',
      name: 'defaultPolicy',
      type: 'CachePolicy',
      defaultValue: 'networkFirst',
      description: 'Policy used when a request does not specify one.',
    ),
    ConfigOption(
      owner: 'CacheConfig',
      name: 'maxMemoryEntries',
      type: 'int',
      defaultValue: '256',
      description: 'Maximum number of entries kept in memory.',
    ),
    ConfigOption(
      owner: 'CacheConfig',
      name: 'persistent',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether entries are also written to the key-value store.',
    ),
    ConfigOption(
      owner: 'CacheConfig',
      name: 'persistKeyPrefix',
      type: 'String',
      defaultValue: 'flutter_guard.cache',
      description: 'Key prefix used in the persistent store.',
    ),
    ConfigOption(
      owner: 'OfflineConfig',
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the offline queue is active.',
    ),
    ConfigOption(
      owner: 'OfflineConfig',
      name: 'persistentQueue',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether queued requests are written to the store.',
    ),
    ConfigOption(
      owner: 'OfflineConfig',
      name: 'autoSync',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether returning online starts a sync automatically.',
    ),
    ConfigOption(
      owner: 'OfflineConfig',
      name: 'maxQueueSize',
      type: 'int',
      defaultValue: '500',
      description: 'Maximum number of pending entries.',
    ),
    ConfigOption(
      owner: 'OfflineConfig',
      name: 'defaultPriority',
      type: 'int',
      defaultValue: '0',
      description: 'Priority assigned when enqueueing without an override.',
    ),
    ConfigOption(
      owner: 'OfflineConfig',
      name: 'queueMutationsByDefault',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether mutations queue automatically when offline.',
    ),
    ConfigOption(
      owner: 'OfflineConfig',
      name: 'persistKey',
      type: 'String',
      defaultValue: 'flutter_guard.offline.queue',
      description: 'Persistent store key for the queue snapshot.',
    ),
    ConfigOption(
      owner: 'DiagnosticsConfig',
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether diagnostics collection is active.',
    ),
    ConfigOption(
      owner: 'DiagnosticsConfig',
      name: 'logLevel',
      type: 'LogLevel',
      defaultValue: 'info (debug in development presets)',
      description: 'Minimum severity written to the logger.',
    ),
    ConfigOption(
      owner: 'DiagnosticsConfig',
      name: 'maxLogEntries',
      type: 'int',
      defaultValue: '500',
      description: 'Maximum in-memory log events retained.',
    ),
    ConfigOption(
      owner: 'DiagnosticsConfig',
      name: 'redactSensitiveFields',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether known secret field names are replaced.',
    ),
    ConfigOption(
      owner: 'DiagnosticsConfig',
      name: 'extraRedactedKeys',
      type: 'List<String>',
      defaultValue: '[]',
      description: 'Additional keys treated as sensitive.',
    ),
    ConfigOption(
      owner: 'DiagnosticsConfig',
      name: 'collectMetrics',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether request timing and counters are recorded.',
    ),
    ConfigOption(
      owner: 'DiagnosticsConfig',
      name: 'slowRequestThreshold',
      type: 'Duration',
      defaultValue: '1000ms',
      description: 'Duration at which a request is counted as slow.',
    ),
    ConfigOption(
      owner: 'InspectorConfig',
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true (false in production presets)',
      description: 'Whether GuardInspector.show may present UI.',
    ),
    ConfigOption(
      owner: 'InspectorConfig',
      name: 'allowInRelease',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the inspector can open in release mode.',
    ),
    ConfigOption(
      owner: 'FeatureFlagConfig',
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether flag evaluation is active.',
    ),
    ConfigOption(
      owner: 'FeatureFlagConfig',
      name: 'flags',
      type: 'Map<String, FeatureFlag>',
      defaultValue: '{}',
      description: 'Seed flags for the local provider.',
    ),
    ConfigOption(
      owner: 'FeatureFlagConfig',
      name: 'userId',
      type: 'String?',
      defaultValue: 'null',
      description: 'Stable identifier used for percentage rollouts.',
    ),
    ConfigOption(
      owner: 'FeatureFlagConfig',
      name: 'appVersion',
      type: 'String?',
      defaultValue: 'null',
      description: 'Semantic app version used for minVersion targeting.',
    ),
    ConfigOption(
      owner: 'FeatureFlagConfig',
      name: 'provider',
      type: 'FeatureFlagProvider?',
      defaultValue: 'LocalFeatureFlagProvider',
      description: 'Optional remote or custom provider.',
    ),
    ConfigOption(
      owner: 'EnvironmentConfig',
      name: 'environment',
      type: 'GuardEnvironment',
      defaultValue: 'development',
      description: 'Current environment.',
    ),
    ConfigOption(
      owner: 'EnvironmentConfig',
      name: 'applyPresets',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether logging and inspector defaults are adjusted.',
    ),
  ];

  /// Options that belong to [owner].
  static List<ConfigOption> forOwner(String owner) {
    return options.where((option) => option.owner == owner).toList();
  }
}
