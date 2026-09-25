import '../../core/exceptions/exceptions.dart';
import '../request/guard_request.dart';
import '../response/api_response.dart';

/// Hook that can observe or rewrite requests, responses, and errors.
///
/// Interceptors run in registration order for requests, and in reverse order
/// for responses and errors.
abstract class GuardInterceptor {
  /// Rewrites or observes a request before it is sent.
  Future<GuardRequest> onRequest(GuardRequest request) async => request;

  /// Rewrites or observes a successful response.
  Future<ApiResponse<dynamic>> onResponse(ApiResponse<dynamic> response) async {
    return response;
  }

  /// Observes a failure. Return the same or a replacement exception.
  Future<FlutterGuardException> onError(FlutterGuardException error) async {
    return error;
  }
}
