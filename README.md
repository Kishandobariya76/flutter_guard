# FlutterGuard

**Production infrastructure for Flutter applications.**

[![Flutter](https://img.shields.io/badge/Flutter-3.44.0-02569B)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

FlutterGuard is an architecture-agnostic SDK for networking, authentication
refresh, caching, offline work, diagnostics, feature flags, and a debug
inspector. It does not require GetX, Bloc, Riverpod, Provider, or any other
state-management package.

## Overview

Use FlutterGuard when you want production client infrastructure without
adopting a full application framework.

The package is one library with replaceable ports:

* `GuardTransport` for HTTP
* `TokenStore` for tokens
* `GuardKeyValueStore` for cache and the offline queue
* `ConnectivityAdapter` for online/offline
* `FeatureFlagProvider` for a future remote source

V1 ships a local feature-flag provider. Remote providers are an extension
point, not an implementation.

## Why FlutterGuard?

Most Flutter apps rebuild the same production machinery: retries, 401
refresh, cache policies, offline writes, and a way to see what the client
just did. FlutterGuard implements that machinery once, keeps it typed, and
demonstrates every option in `example/`.

## Features

* HTTP client with typed responses and interceptors
* Exception hierarchy mapped from HTTP statuses
* Retry with backoff and jitter
* Single-flight token refresh
* In-flight request deduplication
* Request cancellation
* Memory and persistent cache, including stale-while-revalidate
* Offline queue, sync, and conflict resolution
* Page, offset, and cursor pagination
* Connectivity versus reachability
* Structured logging with redaction
* Diagnostics and performance metrics
* In-app inspector
* Local feature flags
* Environment presets
* App lifecycle history
* Debouncer, throttler, and `Result`

## Architecture

```text
Application (setState, Riverpod, Bloc, GetX, …)
        │
        ▼
   FlutterGuard
        │
        ├── GuardNetwork ── GuardTransport (package:http by default)
        ├── GuardAuth ──── TokenStore
        ├── GuardCache ─── GuardKeyValueStore
        ├── GuardOffline ─ queue + GuardSync
        ├── FeatureFlags ─ FeatureFlagProvider
        └── GuardInspector (optional UI)
```

Implementation details live under `lib/src/`. Import
`package:flutter_guard_sdk/flutter_guard_sdk.dart`.

## Installation

The pub.dev name is `flutter_guard_sdk`. The product API is still
`FlutterGuard`. `flutter_guard` could not be used because pub.dev considers
it too similar to the existing `flutter_guards` package.

```yaml
dependencies:
  flutter_guard_sdk: ^0.1.0
```

```bash
flutter pub get
```

## Requirements

| Tool | Minimum |
| --- | --- |
| Flutter | 3.44.0 |
| Dart | 3.12.0 |

Platforms: Android, iOS, web, macOS, Windows, and Linux. The default
transport is `package:http`. Persistence is in-memory unless you inject a
store.

## Quick Start

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterGuard.initialize(
    FlutterGuardConfig(
      baseUrl: 'https://api.example.com',
    ),
  );

  runApp(const MyApp());
}

Future<void> loadUser() async {
  final response = await FlutterGuard.instance.network.get<Map<String, Object?>>(
    '/users/123',
    parser: (json) => Map<String, Object?>.from(json! as Map),
  );
  debugPrint('${response.data}');
}
```

## Configuration

```dart
await FlutterGuard.initialize(
  FlutterGuardConfig(
    baseUrl: 'https://api.example.com',
    network: NetworkConfig(
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 30),
      retry: RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 500),
        maxDelay: Duration(seconds: 10),
        exponentialBackoff: true,
        jitter: true,
      ),
    ),
    auth: AuthConfig(
      accessTokenProvider: () async => readAccessToken(),
      refreshToken: () async => refreshAccessToken(),
    ),
    cache: CacheConfig(
      enabled: true,
      defaultTtl: Duration(minutes: 10),
    ),
    offline: OfflineConfig(
      enabled: true,
      persistentQueue: true,
      autoSync: true,
    ),
    diagnostics: DiagnosticsConfig(enabled: true),
    inspector: InspectorConfig(enabled: true),
  ),
);
```

`EnvironmentConfig.applyPresets` (default `true`) adjusts logging and the
inspector when you pass the default `DiagnosticsConfig` / `InspectorConfig`:

| Environment | Log level | Inspector |
| --- | --- | --- |
| development | debug | enabled |
| staging | info | enabled |
| production | error | disabled |

### Configuration reference

Every public option is also listed in `ConfigCatalog` and shown in the
example **Configuration Playground**.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| FlutterGuardConfig.baseUrl | String? | null | Root URL for relative paths |
| FlutterGuardConfig.network | NetworkConfig | defaults | HTTP settings |
| FlutterGuardConfig.auth | AuthConfig | defaults | Token attachment and refresh |
| FlutterGuardConfig.cache | CacheConfig | defaults | Cache settings |
| FlutterGuardConfig.offline | OfflineConfig | defaults | Queue and sync |
| FlutterGuardConfig.diagnostics | DiagnosticsConfig | preset | Logs and metrics |
| FlutterGuardConfig.inspector | InspectorConfig | preset | Debug inspector |
| FlutterGuardConfig.featureFlags | FeatureFlagConfig | defaults | Local flags |
| FlutterGuardConfig.environment | EnvironmentConfig | development | Presets and targeting |
| FlutterGuardConfig.transport | GuardTransport? | HttpGuardTransport | HTTP adapter |
| FlutterGuardConfig.store | GuardKeyValueStore? | MemoryKeyValueStore | Persistence port |
| FlutterGuardConfig.connectivityAdapter | ConnectivityAdapter? | ManualConnectivityAdapter | Connectivity source |
| NetworkConfig.connectTimeout | Duration | 15s | Connection timeout |
| NetworkConfig.receiveTimeout | Duration | 30s | Response timeout |
| NetworkConfig.sendTimeout | Duration | 30s | Upload timeout |
| NetworkConfig.retry | RetryConfig | defaults | Default retry policy |
| NetworkConfig.defaultHeaders | Map<String, String> | {} | Headers on every request |
| NetworkConfig.followRedirects | bool | true | Follow HTTP redirects |
| NetworkConfig.maxRedirects | int | 5 | Redirect cap |
| NetworkConfig.enableDefaultDeduplication | bool | false | Global in-flight sharing |
| NetworkConfig.userAgent | String | flutter_guard_sdk/0.1.0 | Default User-Agent |
| RetryConfig.maxAttempts | int | 3 | Attempts including the first |
| RetryConfig.initialDelay | Duration | 500ms | Base retry delay |
| RetryConfig.maxDelay | Duration | 10s | Backoff cap |
| RetryConfig.exponentialBackoff | bool | true | Double the delay |
| RetryConfig.jitter | bool | true | Randomize the delay |
| RetryConfig.retryableStatusCodes | Set<int> | {408,429,500,502,503,504} | Retryable statuses |
| RetryConfig.retryNonIdempotent | bool | false | Allow POST/PATCH retries |
| AuthConfig.accessTokenProvider | Function? | null | Current access token |
| AuthConfig.refreshToken | Function? | null | Single-flight refresh |
| AuthConfig.tokenStore | TokenStore? | MemoryTokenStore | Token persistence |
| AuthConfig.refreshStatusCodes | Set<int> | {401} | Statuses that refresh |
| AuthConfig.attachAuthorization | bool | true | Attach the token header |
| AuthConfig.authorizationHeader | String | Authorization | Header name |
| AuthConfig.authorizationPrefix | String | Bearer | Token prefix |
| AuthConfig.maxRefreshAttempts | int | 1 | Refresh attempts per request |
| CacheConfig.enabled | bool | true | Cache master switch |
| CacheConfig.defaultTtl | Duration | 10 minutes | Freshness window |
| CacheConfig.defaultPolicy | CachePolicy | networkFirst | Default policy |
| CacheConfig.maxMemoryEntries | int | 256 | LRU size |
| CacheConfig.persistent | bool | false | Write through the store |
| CacheConfig.persistKeyPrefix | String | flutter_guard.cache | Store prefix |
| OfflineConfig.enabled | bool | true | Queue master switch |
| OfflineConfig.persistentQueue | bool | true | Persist the queue |
| OfflineConfig.autoSync | bool | true | Sync when back online |
| OfflineConfig.maxQueueSize | int | 500 | Queue cap |
| OfflineConfig.defaultPriority | int | 0 | Default priority |
| OfflineConfig.queueMutationsByDefault | bool | true | Queue writes while offline |
| OfflineConfig.persistKey | String | flutter_guard.offline.queue | Store key |
| DiagnosticsConfig.enabled | bool | true | Collect logs/metrics |
| DiagnosticsConfig.logLevel | LogLevel | info (debug in dev) | Minimum severity |
| DiagnosticsConfig.maxLogEntries | int | 500 | Ring-buffer size |
| DiagnosticsConfig.redactSensitiveFields | bool | true | Redact secrets |
| DiagnosticsConfig.extraRedactedKeys | List<String> | [] | Extra secret keys |
| DiagnosticsConfig.collectMetrics | bool | true | Record timings |
| DiagnosticsConfig.slowRequestThreshold | Duration | 1000ms | Slow-request bar |
| InspectorConfig.enabled | bool | true (false in prod) | Allow inspector UI |
| InspectorConfig.allowInRelease | bool | false | Allow release inspector |
| FeatureFlagConfig.enabled | bool | true | Evaluate flags |
| FeatureFlagConfig.flags | Map<String, FeatureFlag> | {} | Seed flags |
| FeatureFlagConfig.userId | String? | null | Rollout identity |
| FeatureFlagConfig.appVersion | String? | null | minVersion targeting |
| FeatureFlagConfig.provider | FeatureFlagProvider? | local | Flag source |
| EnvironmentConfig.environment | GuardEnvironment | development | Current environment |
| EnvironmentConfig.applyPresets | bool | true | Apply logging/inspector presets |

Dartdoc on each field also records purpose, allowed values, a production
note, and common mistakes.

## Network

### Basic

```dart
final response = await guard.network.get<User>(
  '/users/123',
  parser: User.fromJson,
);
```

### Advanced

```dart
final response = await guard.network.send<Order>(
  'POST',
  '/orders',
  data: order.toJson(),
  headers: {'x-request-source': 'checkout'},
  parser: Order.fromJson,
  timeout: const Duration(seconds: 20),
);
```

### HTTP methods

`get`, `post`, `put`, `patch`, `delete`, `head`, `send`, `upload`, and
`download`.

### Typed responses

Pass `parser` to map JSON to your type. `ApiResponse<T>` includes `data`,
`statusCode`, `headers`, `requestId`, `duration`, `fromCache`, `isStale`,
`retryCount`, `timestamp`, `url`, `method`, and `responseSize`.

### Configuration

See `NetworkConfig` above. Per-request overrides: `timeout`, `headers`,
`query`, `deduplicate`, `cachePolicy`, `retry`, `cancelToken`.

### Expected behavior

Statuses `>= 400` throw a `FlutterGuardException` subclass. Successful
bodies are parsed and returned.

### Common mistake

Putting `Authorization` in `NetworkConfig.defaultHeaders` instead of
`AuthConfig`.

### Example application

`example/lib/features/network/network_page.dart`

## Error Handling

```text
FlutterGuardException
├── NetworkException
├── RequestTimeoutException
├── UnauthorizedException
├── ForbiddenException
├── NotFoundException
├── ValidationException
├── RateLimitException
├── ServerException
├── CancelledException
├── CacheException
├── OfflineException
└── UnknownException
```

`RequestTimeoutException` is named to avoid colliding with `dart:async`
`TimeoutException`.

Each type documents when it occurs, its properties, how to handle it, and
whether FlutterGuard retries it. See
`lib/src/core/exceptions/exceptions.dart`.

The example Network screen triggers 401, 403, 404, 422, 429, and 500
through the local demo transport.

## Retry

### Basic

```dart
RetryConfig(maxAttempts: 3)
```

### Advanced

```dart
RetryConfig(
  maxAttempts: 3,
  initialDelay: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 10),
  exponentialBackoff: true,
  jitter: true,
  retryableStatusCodes: {503, 504},
)
```

GET, HEAD, PUT, and DELETE may retry. POST and PATCH do not, unless
`retryNonIdempotent: true` or the call passes `retry: true`.

### Example application

`example/lib/features/retry/retry_page.dart`

## Authentication

### Basic

```dart
AuthConfig(
  accessTokenProvider: () async => storage.readAccess(),
  refreshToken: () async => api.refresh(),
)
```

### Token refresh

If 100 in-flight requests receive 401, FlutterGuard starts **one** refresh.
When it succeeds, the waiting requests retry once with the new token.

Do not store a captured bearer token on the offline queue. Authorization is
applied again at send time.

### Common mistake

Adding `403` to `refreshStatusCodes`. 403 is authorization, not expiry.

### Example application

`example/lib/features/authentication/auth_page.dart`

## Request Deduplication

```dart
await guard.network.get('/dashboard', deduplicate: true);
```

Identical in-flight calls share one transport request. Authorization,
Cookie, and request-id headers are ignored when building the key.

### Example application

`example/lib/features/deduplication/dedup_page.dart`

## Request Cancellation

```dart
final token = CancellationToken();
final future = guard.network.get('/reports', cancelToken: token);
token.cancel();
```

A cancelled request throws `CancelledException` and is not retried.

### Example application

`example/lib/features/cancellation/cancel_page.dart`

## Caching

Policies: `networkOnly`, `cacheOnly`, `cacheFirst`, `networkFirst`,
`staleWhileRevalidate`.

### Stale while revalidate

`get` returns the cached value immediately, including a stale entry, and
refreshes in the background. Use `onRevalidate` to rebuild UI with the
fresh `ApiResponse`.

```dart
final first = await guard.network.get<Catalog>(
  '/catalog',
  cachePolicy: CachePolicy.staleWhileRevalidate,
  parser: Catalog.fromJson,
  onRevalidate: (fresh) => setState(() => catalog = fresh.data),
);
```

### Cache invalidation

```dart
await guard.cache.invalidate('/products');
await guard.cache.invalidateTag('products');
await guard.cache.clear();
```

### Common mistake

Using `cacheOnly` as the global default. The first launch will miss.

### Example application

`example/lib/features/cache/cache_page.dart`

## Connectivity

`ConnectivityStatus` is `unknown`, `offline`, or `online`.

This is **not** internet reachability. A device can be online on a captive
portal and still fail to reach your API. Call
`guard.connectivity.checkReachability(uri: ...)` for a real probe.

FlutterGuard does not invent radio quality. The inspector can show measured
request latency after samples exist.

### Example application

`example/lib/features/connectivity/connectivity_page.dart`

## Offline Queue

Offline POST/PUT/PATCH/DELETE are queued when
`OfflineConfig.queueMutationsByDefault` is true. GET is not queued unless
you pass `queueIfOffline: true`.

`OfflineException.queued` is `true` when the request was stored. Sync drains
pending entries when connectivity returns if `autoSync` is true.

### Conflict resolution

On HTTP 409 the sync engine applies `ConflictStrategy`:

* `serverWins` — keep the server representation
* `clientWins` — resend the client payload
* `lastWriteWins` — compare timestamps
* `custom` — call your `ConflictResolver`
* `manual` — leave `needsResolution`

The example conflict screen executes the resolver. It does not print a fake
success message.

### Example application

`example/lib/features/offline/`

## Pagination

```dart
final paginator = Paginator<Item>.page(
  fetch: (page, pageSize) => api.page(page, pageSize),
);
await paginator.load();
await paginator.loadMore(); // ignored if a loadMore is already running
```

Also `Paginator.offset` and `Paginator.cursor`.

### Example application

`example/lib/features/pagination/pagination_page.dart`

## Diagnostics

`guard.diagnostics` exposes `logger` and `metrics`.
`diagnostics.reset()` clears both. Intended for debug builds.

### Logging

```dart
guard.logger.info('Order submitted', metadata: {'orderId': order.id});
```

Levels: `debug`, `info`, `warning`, `error`, `critical`.

### Log redaction

Values for `Authorization`, `Cookie`, `password`, `token`, `accessToken`,
`refreshToken`, `creditCard`, `secret`, `apiKey`, and common snake_case
aliases are replaced with `********` before they are stored.

Redaction exists because logs and the inspector are easy to screenshot,
share, and persist. Never disable it to "debug auth" in a shared build.

### Performance metrics

Recorded when available: request duration, retry count, cache hit/miss,
queue depth, and response size. Unsupported metrics are not reported.

### Example application

`example/lib/features/diagnostics/diagnostics_page.dart`

## Debug Inspector

```dart
await GuardInspector.show(context);
```

Sections: Overview, Network, Requests, Errors, Logs, Cache, Offline Queue,
Performance, Feature Flags, Environment, Device Information.

The inspector is a no-op when disabled or when the build is release and
`allowInRelease` is false.

### Example application

Open it from the dashboard action or the diagnostics screen.

## Feature Flags

```dart
if (guard.flags.isEnabled('new_checkout')) {
  return const NewCheckout();
}
```

Types: boolean, string, integer, double, JSON. Targeting: rollout
percentage, platform, app version, environment. The V1 provider is local.

### Example application

`example/lib/features/feature_flags/flags_page.dart`

## Environment Configuration

```dart
FlutterGuardConfig(
  environment: EnvironmentConfig(
    environment: GuardEnvironment.production,
  ),
);
```

The example Environment screen shows the live process and the development
versus production presets.

## App Lifecycle

`guard.lifecycle` records `resumed`, `inactive`, `paused`, `detached`, and
`hidden` when a widgets binding exists.

### Example application

`example/lib/features/lifecycle/lifecycle_page.dart`

## Debouncer

```dart
final debouncer = Debouncer(duration: Duration(milliseconds: 300));
onChanged: (text) {
  debouncer.run(() {
    unawaited(guard.network.get('/search', query: {'q': text}));
  });
};
```

### Example application

`example/lib/features/utils/debounce_page.dart`

## Throttler

Leading-edge: the first call in a window runs, later calls are ignored.

### Example application

`example/lib/features/utils/throttle_page.dart`

## Result Type

```dart
final result = await guard.network.getResult<User>(
  '/users/123',
  parser: User.fromJson,
);
result.when(
  success: (response) {},
  failure: (error) {},
);
```

Use `Result` when both outcomes are routine at an application boundary. Use
exceptions when the caller is not expected to recover locally. `get` throws.
`getResult` does not throw `FlutterGuardException`.

## Complete Example Application

```bash
cd example
flutter pub get
flutter run
```

The example uses `DemoTransport`. It does not need a production API.

## Testing

```bash
flutter test
flutter analyze
cd example && flutter test
```

Critical automated cases:

* 100 requests + expired token → 1 refresh, 100 successes
* 100 identical deduplicated requests → 1 transport call
* offline, queue 10, restore, sync → 10 sends

## Production Configuration

```dart
FlutterGuardConfig(
  baseUrl: const String.fromEnvironment('API_BASE_URL'),
  environment: const EnvironmentConfig(
    environment: GuardEnvironment.production,
  ),
  auth: AuthConfig(
    accessTokenProvider: secureStore.readAccess,
    refreshToken: refreshSession,
    tokenStore: SecureTokenStore(),
  ),
  inspector: const InspectorConfig(enabled: false),
  diagnostics: const DiagnosticsConfig(
    logLevel: LogLevel.error,
    redactSensitiveFields: true,
  ),
);
```

Never put production secrets in source.

## Security

* Tokens belong in a `TokenStore` you control, not in source.
* Logs redact known secret keys.
* The inspector is off in production presets.
* Cached and queued bodies can contain personal data. Inject an encrypted
  store if you persist them.
* API keys should come from `--dart-define` or a secrets manager.

## Performance

Debug collectors are bounded by `maxLogEntries`. The inspector is built
only when opened. Dedup entries are removed in `whenComplete`. Cache is
LRU. Retry timers stop when a request is cancelled.

## Troubleshooting

### 401 after token refresh

**Cause:** The refresh handler returned the same expired token, or
`accessTokenProvider` still reads the old value.

**Solution:** Persist the new token before the refresh callback returns.
Make `accessTokenProvider` read that store.

**Debug:** Inspect `guard.auth.refreshCount` and the Authorization header
in the inspector (it will be redacted, but you can see that it changed
length only if you log a hash yourself).

### Infinite retry loop

**Cause:** `maxAttempts` is high and `retryableStatusCodes` includes a
permanent failure, or `retryNonIdempotent` is true on a failing POST.

**Solution:** Keep `maxAttempts` at 2–3. Do not retry 4xx other than 408
and 429.

### Offline queue not syncing

**Cause:** `autoSync` is false, or the adapter still reports offline.

**Solution:** Call `guard.offline.sync()` or set the adapter to `online`.
Confirm with `await guard.connectivity.refresh()`.

### Cache not updating

**Cause:** `cacheFirst` is serving a fresh TTL, or `enabled` is false.

**Solution:** Invalidate the URL or tag, or use `networkFirst` /
`staleWhileRevalidate`.

### Inspector not opening

**Cause:** Production preset, or release mode without `allowInRelease`.

**Solution:** Use a development environment or pass
`InspectorConfig(enabled: true)` explicitly in a debug build.

### Request cancellation

**Cause:** The transport ignored the token.

**Solution:** Custom `GuardTransport` implementations must honor
`request.cancelToken`.

### Connectivity says online but the API fails

**Cause:** Connectivity is not reachability.

**Solution:** Call `checkReachability` and inspect the real HTTP error.

### Duplicate requests

**Cause:** Deduplication is opt-in.

**Solution:** Pass `deduplicate: true` or enable
`enableDefaultDeduplication` for safe GETs only.

### Persistent storage errors

**Cause:** The injected store threw, or persisted JSON is corrupt.

**Solution:** FlutterGuard deletes corrupt cache rows. Replace the store if
writes fail.

### Platform-specific issues

**Cause:** File stores and `dart:io` are not available on web.

**Solution:** Inject a web-safe `GuardKeyValueStore`. Memory works everywhere.

### Release build behavior

**Cause:** Inspector and debug logging are intentionally reduced.

**Solution:** This is expected. Do not enable `allowInRelease` to inspect
production users.

## FAQ

**Does FlutterGuard require Dio?** No. It uses `package:http` and a
`GuardTransport` port.

**Does FlutterGuard require GetX or Bloc?** No.

**Can I use Riverpod or Provider?** Yes. FlutterGuard is not a
state-management library.

**Can I use my own HTTP client?** Yes. Implement `GuardTransport`.

**Can I disable caching, the offline queue, or diagnostics?** Yes. Set
`enabled: false` on the corresponding config.

**Can I use FlutterGuard in production?** Yes. Use the production
environment preset, a secure token store, and keep redaction enabled.

**Does it support Web, iOS, and Android?** Yes.

**How does token refresh work?** One shared refresh, then one retry of the
original request.

**How is sensitive data protected?** Default redaction, memory token store,
inspector disabled in production presets.

## Migration Guide

See [MIGRATION.md](MIGRATION.md). This is the initial release.

## API Reference

Import `package:flutter_guard_sdk/flutter_guard_sdk.dart`. Dartdoc is the source of
truth for parameters, returns, and exceptions.

## Architecture Extension

Future packages can implement the existing ports:

* `flutter_guard_forms`
* `flutter_guard_firebase`
* `flutter_guard_sentry`
* `flutter_guard_cloud`
* `flutter_guard_devtools`

They are not implemented in this repository.

## Roadmap

* Optional secure-storage adapter package
* Optional `connectivity_plus` adapter package
* Remote feature-flag provider package

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security Policy

See [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).

## Example Application Index

```text
Example Application
├── Network                 example/lib/features/network/network_page.dart
├── Authentication          example/lib/features/authentication/auth_page.dart
├── Retry                   example/lib/features/retry/retry_page.dart
├── Deduplication           example/lib/features/deduplication/dedup_page.dart
├── Cancellation            example/lib/features/cancellation/cancel_page.dart
├── Cache                   example/lib/features/cache/cache_page.dart
├── Offline Queue           example/lib/features/offline/offline_queue_page.dart
├── Synchronization         example/lib/features/offline/sync_page.dart
├── Conflict Resolution     example/lib/features/offline/conflict_page.dart
├── Pagination              example/lib/features/pagination/pagination_page.dart
├── Connectivity            example/lib/features/connectivity/connectivity_page.dart
├── Diagnostics             example/lib/features/diagnostics/diagnostics_page.dart
├── Logging                 example/lib/features/diagnostics/diagnostics_page.dart
├── Performance             inspector Performance section
├── Inspector               GuardInspector.show
├── Feature Flags           example/lib/features/feature_flags/flags_page.dart
├── Environment             example/lib/features/environment/environment_page.dart
├── Lifecycle               example/lib/features/lifecycle/lifecycle_page.dart
├── Debounce                example/lib/features/utils/debounce_page.dart
├── Throttle                example/lib/features/utils/throttle_page.dart
└── Configuration           example/lib/features/playground/playground_page.dart
```
