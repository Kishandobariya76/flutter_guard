import '../core/config/auth_config.dart';
import '../core/exceptions/exceptions.dart';
import 'refresh/token_refresh_coordinator.dart';
import 'session/guard_session.dart';
import 'token/token_store.dart';

/// Authentication facade: token attachment, single-flight refresh, session.
class GuardAuth {
  /// Creates an auth facade.
  GuardAuth({required AuthConfig config, TokenStore? store})
    : _config = config,
      _store = store ?? config.tokenStore ?? MemoryTokenStore();

  final AuthConfig _config;
  final TokenStore _store;
  final TokenRefreshCoordinator _refresh = TokenRefreshCoordinator();
  bool _expired = false;
  int _refreshCount = 0;

  /// Active configuration.
  AuthConfig get config => _config;

  /// Token store in use.
  TokenStore get store => _store;

  /// Whether a refresh callback is configured.
  bool get canRefresh => _config.refreshToken != null;

  /// Number of completed refresh attempts in this process.
  int get refreshCount => _refreshCount;

  /// Whether a refresh is currently running.
  bool get isRefreshing => _refresh.isRefreshing;

  /// Current session snapshot.
  Future<GuardSession> session() async {
    final access = await currentAccessToken();
    final refresh = await _store.readRefreshToken();
    return GuardSession(
      hasAccessToken: access != null && access.isNotEmpty,
      hasRefreshToken: refresh != null && refresh.isNotEmpty,
      expired: _expired,
    );
  }

  /// Returns the access token from the provider or the store.
  Future<String?> currentAccessToken() async {
    if (_config.accessTokenProvider != null) {
      return _config.accessTokenProvider!();
    }
    return _store.readAccessToken();
  }

  /// Persists tokens and clears the expired flag.
  Future<void> login({
    required String accessToken,
    String? refreshToken,
  }) async {
    _expired = false;
    await _store.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Clears tokens and marks the session signed out.
  Future<void> logout() async {
    _expired = false;
    await _store.clear();
  }

  /// Marks the session expired after a failed refresh.
  Future<void> expire() async {
    _expired = true;
    await _store.clear();
  }

  /// Attaches the configured authorization header when a token exists.
  Future<Map<String, String>> authorize(Map<String, String> headers) async {
    if (!_config.attachAuthorization) {
      return headers;
    }
    if (headers.keys.any(
      (key) => key.toLowerCase() == _config.authorizationHeader.toLowerCase(),
    )) {
      return headers;
    }
    final token = await currentAccessToken();
    if (token == null || token.isEmpty) {
      return headers;
    }
    return <String, String>{
      ...headers,
      _config.authorizationHeader: '${_config.authorizationPrefix}$token',
    };
  }

  /// Runs a single-flight refresh and stores the new access token.
  Future<String> refresh() async {
    if (!canRefresh) {
      throw const UnauthorizedException('No refresh handler is configured');
    }
    try {
      final token = await _refresh.refresh(() async {
        final next = await _config.refreshToken!();
        if (next == null || next.isEmpty) {
          throw const UnauthorizedException(
            'Refresh handler returned no token',
          );
        }
        await _store.writeTokens(accessToken: next);
        _refreshCount += 1;
        _expired = false;
        return next;
      });
      if (token == null || token.isEmpty) {
        throw const UnauthorizedException('Refresh handler returned no token');
      }
      return token;
    } on UnauthorizedException {
      await expire();
      rethrow;
    } catch (error) {
      await expire();
      throw UnauthorizedException('Token refresh failed', cause: error);
    }
  }
}
