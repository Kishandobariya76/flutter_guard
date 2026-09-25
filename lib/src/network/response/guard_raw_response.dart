/// Bytes and metadata returned by a [GuardTransport].
class GuardRawResponse {
  /// Creates a raw response.
  const GuardRawResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
    this.requestId,
  });

  /// HTTP status.
  final int statusCode;

  /// Response headers. Keys are lower-cased by the default transport.
  final Map<String, String> headers;

  /// Raw body.
  final List<int> bodyBytes;

  /// Request id echoed by the transport, when available.
  final String? requestId;

  /// Decodes [bodyBytes] as UTF-8. Returns an empty string when there is no
  /// body.
  String get body => String.fromCharCodes(bodyBytes);
}
