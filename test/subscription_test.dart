/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:async';
import 'package:test/test.dart';
import 'package:transmit_client/src/hook.dart';
import 'package:transmit_client/src/subscription.dart';
import 'package:transmit_client/src/subscription_status.dart';
import 'package:transmit_client/src/transmit_status.dart';
import 'test_utils/fake_http_client.dart';

final client = FakeHttpClient(
  baseUrl: 'http://localhost',
  uid: '1',
);

final hook = Hook();

Subscription subscriptionFactory([TransmitStatus Function()? statusFactory]) {
  return Subscription(SubscriptionOptions(
    channel: 'foo',
    httpClient: client,
    hooks: hook,
    getEventSourceStatus: statusFactory ?? () => TransmitStatus.connected,
  ));
}

void main() {
  group('Subscription', () {
    setUp(() {
      client.reset();
    });

    test('should be pending by default', () {
      final subscription = subscriptionFactory();

      expect(subscription.isCreated, isFalse);
      expect(subscription.isDeleted, isFalse);
    });

    test('should create a subscription', () async {
      final subscription = subscriptionFactory();

      await subscription.create();

      expect(subscription.isCreated, isTrue);
      expect(client.sentRequests.length, equals(1));
    });

    test('should not create a subscription when already created', () async {
      final subscription = subscriptionFactory();

      await subscription.create();
      await subscription.create();

      expect(subscription.isCreated, isTrue);
      expect(client.sentRequests.length, equals(1));
    });

    test('should not create a subscription when event source is not connected',
        () async {
      var status = TransmitStatus.connecting;
      final subscription = subscriptionFactory(() => status);

      unawaited(subscription.create());

      // Wait for the request to be sent
      await Future.delayed(const Duration(milliseconds: 500));

      expect(subscription.isCreated, isFalse);
      expect(client.sentRequests.length, equals(0));

      // Change the status to connected to avoid setTimeout loop
      status = TransmitStatus.connected;
    });

    test('should delete a subscription', () async {
      final subscription = subscriptionFactory();

      await subscription.create();

      expect(subscription.isCreated, isTrue);
      expect(client.sentRequests.length, equals(1));

      await subscription.delete();

      expect(subscription.isDeleted, isTrue);
      expect(client.sentRequests.length, equals(2));
    });

    test('should not delete a subscription when already deleted', () async {
      final subscription = subscriptionFactory();

      await subscription.create();

      expect(subscription.isCreated, isTrue);
      expect(client.sentRequests.length, equals(1));

      await subscription.delete();

      expect(subscription.isDeleted, isTrue);
      expect(client.sentRequests.length, equals(2));

      await subscription.delete();

      expect(client.sentRequests.length, equals(2));
    });

    test('should not delete a subscription when not created', () async {
      final subscription = subscriptionFactory();

      await subscription.delete();

      expect(subscription.isDeleted, isFalse);
      expect(client.sentRequests.length, equals(0));
    });

    test('should register a handler', () {
      final subscription = subscriptionFactory();
      var called = false;

      subscription.onMessage((payload) {
        called = true;
      });

      subscription.$runHandler(null);
      expect(called, isTrue);
    });

    test('should run all registered handlers', () {
      final subscription = subscriptionFactory();
      var callCount = 0;

      subscription.onMessage((payload) {
        expect(payload, equals(1));
        callCount++;
      });

      subscription.onMessage((payload) {
        expect(payload, equals(1));
        callCount++;
      });

      subscription.$runHandler(1);
      expect(callCount, equals(2));
    });

    test('should run only once some handler', () {
      final subscription = subscriptionFactory();
      var callCount = 0;

      subscription.onMessageOnce((payload) {
        callCount++;
      });

      subscription.$runHandler(null);
      subscription.$runHandler(null);
      expect(callCount, equals(1));
    });

    test('should get the number of registered handlers', () {
      final subscription = subscriptionFactory();

      subscription.onMessage((payload) {});
      subscription.onMessage((payload) {});

      expect(subscription.handlerCount, equals(2));
    });
  });
}

// Helper function to mark futures as unawaited
void unawaited(Future<void> future) {
  // Intentionally not awaited
}

