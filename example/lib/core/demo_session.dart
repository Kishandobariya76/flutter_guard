import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';

/// In-memory auth session used by the example transport.
class DemoSession {
  String? accessToken;
  String? refreshToken;
  bool expired = false;
  int refreshCount = 0;

  Future<String?> readAccess() async {
    if (expired) {
      return accessToken;
    }
    return accessToken;
  }

  Future<String?> refresh() async {
    if (refreshToken == null) {
      return null;
    }
    refreshCount += 1;
    accessToken = 'demo-access-token-${refreshCount + 1}';
    expired = false;
    return accessToken;
  }

  void login() {
    accessToken = 'demo-access-token-1';
    refreshToken = 'demo-refresh-token';
    expired = false;
    refreshCount = 0;
  }

  void logout() {
    accessToken = null;
    refreshToken = null;
    expired = false;
  }
}

/// Process-wide demo adapter so screens can toggle offline.
final demoConnectivity = ManualConnectivityAdapter();
final demoSession = DemoSession();
final demoStore = MemoryKeyValueStore();
