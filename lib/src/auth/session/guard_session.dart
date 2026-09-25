/// Snapshot of the current authentication session.
class GuardSession {
  /// Creates a session snapshot.
  const GuardSession({
    this.hasAccessToken = false,
    this.hasRefreshToken = false,
    this.expired = false,
  });

  /// Whether an access token is stored.
  final bool hasAccessToken;

  /// Whether a refresh token is stored.
  final bool hasRefreshToken;

  /// Whether the session was marked expired after a failed refresh.
  final bool expired;

  /// Whether the user appears signed in.
  bool get isAuthenticated => hasAccessToken && !expired;
}
