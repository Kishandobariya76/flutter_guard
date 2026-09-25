/// Multipart form payload.
class GuardMultipart {
  /// Creates a multipart payload.
  const GuardMultipart({
    this.fields = const <String, String>{},
    this.files = const <GuardMultipartFile>[],
  });

  /// Text fields.
  final Map<String, String> fields;

  /// File parts.
  final List<GuardMultipartFile> files;
}

/// One file part of a multipart request.
class GuardMultipartFile {
  /// Creates a file part from bytes.
  const GuardMultipartFile({
    required this.field,
    required this.filename,
    required this.bytes,
    this.contentType,
  });

  /// Form field name.
  final String field;

  /// File name sent to the server.
  final String filename;

  /// File contents.
  final List<int> bytes;

  /// Optional MIME type such as `image/png`.
  final String? contentType;
}
