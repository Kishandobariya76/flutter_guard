import '../../auth/token/token_store.dart';

/// Authentication and token-refresh settings.
class AuthConfig {
  /// Creates auth settings.
  const AuthConfig({
    this.accessTokenProvider,
    this.refreshToken,
    this.tokenStore,
    this.refreshStatusCodes = const <int>{401},
    this.attachAuthorization = true,
    this.authorizationHeader = 'Authorization',
    this.authorizationPrefix = 'Bearer ',
    this.maxRefreshAttempts = 1,
  });

  /// Returns the current access token, or `null` when the user is signed out.
  ///
  /// **Type:** `Future<String?> Function()?`
  /// **Required:** no
  /// **Default:** `null`
  /// **Purpose:** Supplies a token for the `Authorization` header.
  /// **Allowed values:** Any async callback that returns a token string.
  /// **Example:** `AuthConfig(accessTokenProvider: () async => readToken())`
  /// **Production recommendation:** Read from a secure store, not from source.
  /// **Common mistakes:** Returning a hard-coded production token.
  final Future<String?> Function()? accessTokenProvider;

  /// Exchanges a refresh token for a new access token.
  ///
  /// **Type:** `Future<String?> Function()?`
  /// **Required:** no
  /// **Default:** `null`
  /// **Purpose:** Allows concurrent 401s to share one refresh request.
  /// **Allowed values:** Any async callback that returns a new access token.
  /// **Example:** `AuthConfig(refreshToken: () async => refresh())`
  /// **Production recommendation:** Persist the new token before returning.
  /// **Common mistakes:** Starting a new refresh per request instead of using
  /// this callback.
  final Future<String?> Function()? refreshToken;

  /// Optional durable token store.
  ///
  /// **Type:** [TokenStore]?
  /// **Required:** no
  /// **Default:** in-memory store
  /// **Purpose:** Lets you inject `flutter_secure_storage` or another adapter.
  /// **Allowed values:** Any [TokenStore].
  /// **Example:** `AuthConfig(tokenStore: SecureTokenStore())`
  /// **Production recommendation:** Use a platform secure store.
  /// **Common mistakes:** Writing tokens to an unencrypted file store.
  final TokenStore? tokenStore;

  /// HTTP statuses that trigger a refresh-and-retry.
  ///
  /// **Type:** `Set<int>`
  /// **Required:** no
  /// **Default:** `{401}`
  /// **Purpose:** Matches APIs that signal expiry with 401.
  /// **Allowed values:** Valid HTTP status codes.
  /// **Example:** `AuthConfig(refreshStatusCodes: {401})`
  /// **Production recommendation:** Keep this as `{401}` unless your API uses
  /// another contract.
  /// **Common mistakes:** Adding `403`, which is an authorization failure.
  final Set<int> refreshStatusCodes;

  /// Whether FlutterGuard attaches the access token automatically.
  ///
  /// **Type:** `bool`
  /// **Required:** no
  /// **Default:** `true`
  /// **Purpose:** Avoids repeating header code on every call.
  /// **Allowed values:** `true`, `false`
  /// **Example:** `AuthConfig(attachAuthorization: true)`
  /// **Production recommendation:** Keep enabled.
  /// **Common mistakes:** Attaching a token both here and in default headers.
  final bool attachAuthorization;

  /// Header that receives the access token.
  ///
  /// **Type:** `String`
  /// **Required:** no
  /// **Default:** `Authorization`
  /// **Purpose:** Supports APIs that use a custom header.
  /// **Allowed values:** Any header name.
  /// **Example:** `AuthConfig(authorizationHeader: 'Authorization')`
  /// **Production recommendation:** Keep the standard header when possible.
  /// **Common mistakes:** Using a custom header and forgetting to redact it.
  final String authorizationHeader;

  /// Prefix written before the token, including any trailing space.
  ///
  /// **Type:** `String`
  /// **Required:** no
  /// **Default:** `Bearer `
  /// **Purpose:** Supports `Bearer`, `Token`, or raw-token APIs.
  /// **Allowed values:** Any string, including empty.
  /// **Example:** `AuthConfig(authorizationPrefix: 'Bearer ')`
  /// **Production recommendation:** `Bearer ` for OAuth-style APIs.
  /// **Common mistakes:** Forgetting the trailing space.
  final String authorizationPrefix;

  /// How many times a single request may trigger refresh.
  ///
  /// **Type:** `int`
  /// **Required:** no
  /// **Default:** `1`
  /// **Purpose:** Prevents an infinite 401 → refresh → 401 loop.
  /// **Allowed values:** `1` recommended.
  /// **Example:** `AuthConfig(maxRefreshAttempts: 1)`
  /// **Production recommendation:** `1`.
  /// **Common mistakes:** Raising this when the refresh endpoint is broken.
  final int maxRefreshAttempts;

  /// Default auth settings with no providers.
  static const AuthConfig defaults = AuthConfig();
}
