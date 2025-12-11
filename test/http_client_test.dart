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

    test('should set and use headers via setHeaders method', () {
      final client = HttpClient(
        baseUrl: 'http://localhost',
        uid: '1',
      );

      // Set headers
      client.setHeaders({
        'Authorization': 'Bearer token-123',
        'X-User-Id': '456',
      });

      final request = client.createRequest('/test', {'foo': 'bar'});

      expect(request.headers['Content-Type'], equals('application/json'));
      expect(request.headers['Authorization'], equals('Bearer token-123'));
      expect(request.headers['X-User-Id'], equals('456'));

      // Clear headers
      client.setHeaders(null);
      final requestAfterClear = client.createRequest('/test', {'foo': 'bar'});

      expect(requestAfterClear.headers['Content-Type'], equals('application/json'));
      expect(requestAfterClear.headers['Authorization'], isNull);
      expect(requestAfterClear.headers['X-User-Id'], isNull);
    });

    test('should return current headers via getHeaders method', () {
      final client = HttpClient(
        baseUrl: 'http://localhost',
        uid: '1',
      );

      expect(client.getHeaders(), isEmpty);

      client.setHeaders({
        'Authorization': 'Bearer token',
      });

      expect(client.getHeaders(), equals({'Authorization': 'Bearer token'}));

      client.setHeaders(null);
      expect(client.getHeaders(), isEmpty);
    });
  });
}


