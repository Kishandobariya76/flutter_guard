import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/exceptions/exceptions.dart';
import '../request/guard_request.dart';
import '../response/guard_raw_response.dart';
import 'guard_transport.dart';

/// Default transport backed by `package:http`.
class HttpGuardTransport implements GuardTransport {
  /// Creates a transport.
  HttpGuardTransport({
    http.Client? client,
    this.followRedirects = true,
    this.maxRedirects = 5,
  }) : _client = client,
       _ownsClient = client == null;

  final http.Client? _client;
  final bool _ownsClient;

  /// Whether redirects are followed.
  final bool followRedirects;

  /// Maximum redirects.
  final int maxRedirects;

  http.Client _createClient() => _client ?? http.Client();

  @override
  Future<GuardRawResponse> send(GuardRequest request) async {
    request.cancelToken?.throwIfCancelled(requestId: request.requestId);
    final client = _createClient();
    final shouldClose = _client == null;
    var closed = false;

    void closeClient() {
      if (shouldClose && !closed) {
        closed = true;
        client.close();
      }
    }

    request.cancelToken?.addListener(closeClient);

    try {
      final http.BaseRequest httpRequest = _buildRequest(request);
      final timeout = request.timeout;
      final streamed = timeout == null
          ? await client.send(httpRequest)
          : await client
                .send(httpRequest)
                .timeout(
                  timeout,
                  onTimeout: () {
                    throw RequestTimeoutException(
                      'Request timed out after $timeout',
                      requestId: request.requestId,
                      timeout: timeout,
                    );
                  },
                );
      request.cancelToken?.throwIfCancelled(requestId: request.requestId);
      final response = timeout == null
          ? await http.Response.fromStream(streamed)
          : await http.Response.fromStream(streamed).timeout(
              timeout,
              onTimeout: () {
                throw RequestTimeoutException(
                  'Response timed out after $timeout',
                  requestId: request.requestId,
                  timeout: timeout,
                );
              },
            );
      request.cancelToken?.throwIfCancelled(requestId: request.requestId);
      return GuardRawResponse(
        statusCode: response.statusCode,
        headers: <String, String>{
          for (final entry in response.headers.entries)
            entry.key.toLowerCase(): entry.value,
        },
        bodyBytes: response.bodyBytes,
        requestId: request.requestId,
      );
    } on FlutterGuardException {
      rethrow;
    } on TimeoutException catch (error) {
      throw RequestTimeoutException(
        'Request timed out',
        cause: error,
        requestId: request.requestId,
        timeout: request.timeout,
      );
    } on http.ClientException catch (error) {
      if (request.cancelToken?.isCancelled ?? false) {
        throw CancelledException(
          'Request was cancelled',
          cause: error,
          requestId: request.requestId,
        );
      }
      throw NetworkException(
        error.message,
        cause: error,
        requestId: request.requestId,
      );
    } catch (error) {
      if (request.cancelToken?.isCancelled ?? false) {
        throw CancelledException(
          'Request was cancelled',
          cause: error,
          requestId: request.requestId,
        );
      }
      throw NetworkException(
        error.toString(),
        cause: error,
        requestId: request.requestId,
      );
    } finally {
      request.cancelToken?.removeListener(closeClient);
      closeClient();
    }
  }

  http.BaseRequest _buildRequest(GuardRequest request) {
    if (request.multipart != null) {
      final multipart = http.MultipartRequest(request.method, request.url);
      multipart.followRedirects = followRedirects;
      multipart.maxRedirects = maxRedirects;
      multipart.headers.addAll(request.headers);
      multipart.fields.addAll(request.multipart!.fields);
      for (final file in request.multipart!.files) {
        multipart.files.add(
          http.MultipartFile.fromBytes(
            file.field,
            file.bytes,
            filename: file.filename,
            contentType: file.contentType == null
                ? null
                : http.MediaType.parse(file.contentType!),
          ),
        );
      }
      return multipart;
    }

    final httpRequest = http.Request(request.method, request.url);
    httpRequest.followRedirects = followRedirects;
    httpRequest.maxRedirects = maxRedirects;
    httpRequest.headers.addAll(request.headers);
    final data = request.data;
    if (data == null) {
      return httpRequest;
    }
    if (data is List<int>) {
      httpRequest.bodyBytes = data;
    } else if (data is String) {
      httpRequest.body = data;
    } else {
      httpRequest.body = jsonEncode(data);
      httpRequest.headers.putIfAbsent(
        'content-type',
        () => 'application/json; charset=utf-8',
      );
    }
    return httpRequest;
  }

  @override
  Future<void> close() async {
    if (_ownsClient) {
      _client?.close();
    }
  }
}
