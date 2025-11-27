/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:transmit_client/src/hook.dart';
import 'package:transmit_client/src/hook_event.dart';

void main() {
  group('Hook', () {
    test('should register a handler for beforeSubscribe event', () {
      final hook = Hook();
      var called = false;

      hook.register(HookEvent.beforeSubscribe, (http.Request request) {
        called = true;
        expect(request.url.toString(), 'http://localhost');
      });

      hook.beforeSubscribe(http.Request('POST', Uri.parse('http://localhost')));
      expect(called, isTrue);
    });

    test('should register a handler for beforeUnsubscribe event', () {
      final hook = Hook();
      var called = false;

      hook.register(HookEvent.beforeUnsubscribe, (http.Request request) {
        called = true;
      });

      hook.beforeUnsubscribe(http.Request('POST', Uri.parse('http://localhost')));
      expect(called, isTrue);
    });

    test('should register a handler for onReconnectAttempt event', () {
      final hook = Hook();
      var called = false;
      var attemptValue = 0;

      hook.register(HookEvent.onReconnectAttempt, (int attempt) {
        called = true;
        attemptValue = attempt;
      });

      hook.onReconnectAttempt(5);
      expect(called, isTrue);
      expect(attemptValue, equals(5));
    });

    test('should register a handler for onReconnectFailed event', () {
      final hook = Hook();
      var called = false;

      hook.register(HookEvent.onReconnectFailed, () {
        called = true;
      });

      hook.onReconnectFailed();
      expect(called, isTrue);
    });

    test('should register a handler for onSubscribeFailed event', () {
      final hook = Hook();
      var called = false;

      hook.register(HookEvent.onSubscribeFailed, (http.Response response) {
        called = true;
        expect(response.statusCode, equals(500));
      });

      hook.onSubscribeFailed(http.Response('', 500));
      expect(called, isTrue);
    });

    test('should register a handler for onSubscription event', () {
      final hook = Hook();
      var called = false;
      var channelValue = '';

      hook.register(HookEvent.onSubscription, (String channel) {
        called = true;
        channelValue = channel;
      });

      hook.onSubscription('test-channel');
      expect(called, isTrue);
      expect(channelValue, equals('test-channel'));
    });

    test('should register a handler for onUnsubscription event', () {
      final hook = Hook();
      var called = false;
      var channelValue = '';

      hook.register(HookEvent.onUnsubscription, (String channel) {
        called = true;
        channelValue = channel;
      });

      hook.onUnsubscription('test-channel');
      expect(called, isTrue);
      expect(channelValue, equals('test-channel'));
    });

    test('should register multiple handlers for beforeSubscribe event', () {
      final hook = Hook();
      var callCount = 0;

      hook.register(HookEvent.beforeSubscribe, (http.Request request) {
        callCount++;
      });

      hook.register(HookEvent.beforeSubscribe, (http.Request request) {
        callCount++;
      });

      hook.beforeSubscribe(http.Request('POST', Uri.parse('http://localhost')));
      expect(callCount, equals(2));
    });

    test('should register multiple handlers for onReconnectFailed event', () {
      final hook = Hook();
      var callCount = 0;

      hook.register(HookEvent.onReconnectFailed, () {
        callCount++;
      });

      hook.register(HookEvent.onReconnectFailed, () {
        callCount++;
      });

      hook.onReconnectFailed();
      expect(callCount, equals(2));
    });

    test('should not throw error when no handlers are defined', () {
      final hook = Hook();
      expect(
        () => hook.beforeSubscribe(http.Request('POST', Uri.parse('http://localhost'))),
        returnsNormally,
      );
    });
  });
}


