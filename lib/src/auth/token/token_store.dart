/// Persistence port for access and refresh tokens.
///
/// The default implementation is in-memory. Production apps should inject a
/// store backed by the platform keychain or another encrypted medium.
abstract class TokenStore {
  /// Reads the current access token.
  Future<String?> readAccessToken();

  /// Reads the current refresh token.
  Future<String?> readRefreshToken();

  /// Persists tokens. Passing `null` clears that field.
  Future<void> writeTokens({String? accessToken, String? refreshToken});

  /// Removes both tokens.
  Future<void> clear();
}

/// Process-local token store. Tokens are lost when the isolate dies.
class MemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> writeTokens({String? accessToken, String? refreshToken}) async {
    if (accessToken != null) {
      _accessToken = accessToken;
    }
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
