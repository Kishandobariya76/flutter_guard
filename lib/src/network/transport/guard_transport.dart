import '../request/guard_request.dart';
import '../response/guard_raw_response.dart';

/// Low-level HTTP port. The rest of FlutterGuard never talks to `package:http`
/// directly.
///
/// Implement this to reuse Dio, Chopper, or a mock server.
abstract class GuardTransport {
  /// Sends one request and returns the raw response.
  ///
  /// Implementations must honor [GuardRequest.timeout] and
  /// [GuardRequest.cancelToken] when they are present.
  Future<GuardRawResponse> send(GuardRequest request);

  /// Releases pooled connections. The default implementation does nothing.
  Future<void> close() async {}
}
