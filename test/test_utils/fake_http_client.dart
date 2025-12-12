/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'package:http/http.dart' as http;
import 'package:transmit_client/src/http_client.dart';

/// Fake HTTP client for testing.
class FakeHttpClient extends HttpClient {
  final List<http.Request> sentRequests = [];

  FakeHttpClient({required super.baseUrl, required super.uid});

  @override
  Future<http.Response> send(http.Request request) async {
    sentRequests.add(request);
    return http.Response('', 200);
  }

  /// Reset the list of sent requests.
  void reset() {
    sentRequests.clear();
  }
}

