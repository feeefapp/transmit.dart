/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'http_client_stub.dart'
    if (dart.library.html) 'http_client_web.dart'
    if (dart.library.io) 'http_client_io.dart';

/// HTTP client for communicating with the Transmit server.
class TransmitHttpClient {
  final String baseUrl;
  final String uid;
  Map<String, String> _headers = {};
  final Dio _dio;

  TransmitHttpClient({
    required this.baseUrl,
    required this.uid,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              followRedirects: false,
              // We map all status codes back to http.Response,
              // so let dio accept all.
              validateStatus: (_) => true,
              responseType: ResponseType.plain,
            ));

  /// Send an HTTP request using Dio under the hood while returning
  /// an http.Response for compatibility with existing hooks/tests.
  Future<http.Response> send(http.Request request) async {
    final options = Options(
      method: request.method,
      headers: request.headers,
      responseType: ResponseType.plain,
      validateStatus: (_) => true,
    );

    final dioResponse = await _dio.requestUri(
      request.url,
      data: request.body.isNotEmpty ? request.body : null,
      options: options,
    );

    final rawHeaders = <String, String>{};
    dioResponse.headers.forEach((key, values) {
      rawHeaders[key] = values.join(',');
    });

    final bodyString = dioResponse.data is String
        ? dioResponse.data as String
        : jsonEncode(dioResponse.data);

    return http.Response(
      bodyString,
      dioResponse.statusCode ?? 500,
      headers: rawHeaders,
      request: request,
      isRedirect: dioResponse.isRedirect ?? false,
      persistentConnection: true,
      reasonPhrase: dioResponse.statusMessage,
    );
  }

  /// Set headers that will be included in all HTTP requests.
  /// Useful for setting authentication headers when user logs in/out.
  /// [headers] - Map with header key-value pairs, or null to clear headers
  ///
  /// Example:
  /// ```dart
  /// // When user logs in
  /// httpClient.setHeaders({
  ///   'Authorization': 'Bearer token-123',
  ///   'X-User-Id': '123'
  /// });
  ///
  /// // When user logs out
  /// httpClient.setHeaders(null);
  /// ```
  void setHeaders(Map<String, String>? headers) {
    if (headers == null) {
      _headers = {};
    } else {
      _headers = Map<String, String>.from(headers);
    }
  }

  /// Get the current headers that are set via setHeaders.
  Map<String, String> getHeaders() {
    return Map<String, String>.from(_headers);
  }

  /// Create a request for subscribing or unsubscribing.
  http.Request createRequest(String path, Map<String, dynamic> body) {
    final url = Uri.parse('$baseUrl$path');
    final requestBody = jsonEncode({'uid': uid, ...body});

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..headers['X-XSRF-TOKEN'] = retrieveXsrfToken() ?? ''
      ..body = requestBody;

    // Merge stored headers (set via setHeaders method)
    request.headers.addAll(_headers);

    return request;
  }

  /// Retrieve XSRF token from cookies (platform-specific).
  String? retrieveXsrfToken() => retrieveXsrfTokenImpl();
}


