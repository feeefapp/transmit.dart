/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_client_stub.dart'
    if (dart.library.html) 'http_client_web.dart'
    if (dart.library.io) 'http_client_io.dart';

/// HTTP client for communicating with the Transmit server.
class HttpClient {
  final String baseUrl;
  final String uid;

  HttpClient({
    required this.baseUrl,
    required this.uid,
  });

  /// Send an HTTP request.
  Future<http.Response> send(http.Request request) async {
    final client = http.Client();
    try {
      return await client.send(request).then(http.Response.fromStream);
    } finally {
      client.close();
    }
  }

  /// Create a request for subscribing or unsubscribing.
  http.Request createRequest(String path, Map<String, dynamic> body) {
    final url = Uri.parse('$baseUrl$path');
    final requestBody = jsonEncode({'uid': uid, ...body});

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..headers['X-XSRF-TOKEN'] = retrieveXsrfToken() ?? ''
      ..body = requestBody;

    return request;
  }

  /// Retrieve XSRF token from cookies (platform-specific).
  String? retrieveXsrfToken() => retrieveXsrfTokenImpl();
}


