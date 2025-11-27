/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'package:test/test.dart';
import 'package:transmit_client/src/http_client.dart';

void main() {
  group('HttpClient', () {
    test('should create a request instance', () {
      final client = HttpClient(
        baseUrl: 'http://localhost',
        uid: '1',
      );

      final request = client.createRequest('/test', {'foo': 'bar'});

      expect(request.url.toString(), equals('http://localhost/test'));
      expect(request.method, equals('POST'));
      expect(request.headers['Content-Type'], equals('application/json'));
      expect(request.headers['X-XSRF-TOKEN'], isNotNull);
    });

    test('should include uid and body in request', () async {
      final client = HttpClient(
        baseUrl: 'http://localhost',
        uid: 'test-uid',
      );

      final request = client.createRequest('/test', {'channel': 'test-channel'});

      expect(request.body, contains('test-uid'));
      expect(request.body, contains('test-channel'));
    });
  });
}


