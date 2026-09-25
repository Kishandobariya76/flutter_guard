/// Ensures concurrent 401s share a single refresh call.
class TokenRefreshCoordinator {
  Future<String?>? _inFlight;

  /// Whether a refresh is currently running.
  bool get isRefreshing => _inFlight != null;

  /// Runs [refresh] or joins the in-flight refresh.
  Future<String?> refresh(Future<String?> Function() refresh) {
    return _inFlight ??= () async {
      try {
        return await refresh();
      } finally {
        _inFlight = null;
      }
    }();
  }
}
