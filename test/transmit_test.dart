/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:async';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:transmit_client/src/transmit.dart';
import 'package:transmit_client/src/subscription.dart';
import 'package:transmit_client/src/http_client.dart';
import 'package:transmit_client/src/transmit_status.dart';
import 'test_utils/fake_sse_channel.dart';
import 'test_utils/fake_http_client.dart';

void main() {
  group('Transmit', () {
    test('should connect to the server', () async {
      FakeEventSource? eventSource;

      final transmit = Transmit(TransmitOptions(
        baseUrl: 'http://localhost',
        uidGenerator: () => '1',
        eventSourceFactory: (url, {withCredentials}) {
          eventSource = FakeEventSource(url, withCredentials: withCredentials);
          return eventSource!;
        },
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(eventSource, isNotNull);
      expect(eventSource?.url.toString(), contains('http://localhost/__transmit/events'));
      expect(eventSource?.url.queryParameters['uid'], equals('1'));
    });

    test('should allow to create subscription', () async {
      final transmit = Transmit(TransmitOptions(
        baseUrl: 'http://localhost',
        uidGenerator: () => '1',
        eventSourceFactory: (url, {withCredentials}) => FakeEventSource(url, withCredentials: withCredentials),
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      final subscription = transmit.subscription('channel');

      expect(subscription, isA<Subscription>());
    });

    test('should allow to customize the uid generator', () async {
      final transmit = Transmit(TransmitOptions(
        baseUrl: 'http://localhost',
        uidGenerator: () => 'custom-uid',
        eventSourceFactory: (url, {withCredentials}) => FakeEventSource(url, withCredentials: withCredentials),
      ));

      expect(transmit.uid, equals('custom-uid'));
    });

    test('should compute uuid when uid generator is not defined', () async {
      final transmit = Transmit(TransmitOptions(
        baseUrl: 'http://localhost',
        eventSourceFactory: (url, {withCredentials}) => FakeEventSource(url, withCredentials: withCredentials),
      ));

      expect(transmit.uid, isA<String>());
      expect(transmit.uid.length, greaterThan(0));
    });

    test('should dispatch messages to the subscriptions', () async {
      FakeEventSource? eventSource;

      final transmit = Transmit(TransmitOptions(
        baseUrl: 'http://localhost',
        uidGenerator: () => '1',
        eventSourceFactory: (url, {withCredentials}) {
          eventSource = FakeEventSource(url, withCredentials: withCredentials);
          return eventSource!;
        },
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      final subscription = transmit.subscription('channel');
      var receivedPayload = '';

      subscription.onMessage((payload) {
        receivedPayload = payload as String;
      });

      eventSource?.emitMessage(
        jsonEncode({'channel': 'channel', 'payload': 'hello'}),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(receivedPayload, equals('hello'));
    });

    test(
        'should not register subscription if they are not created on connection failure',
        () async {
      FakeEventSource? eventSource;
      FakeHttpClient? httpClient;

      final transmit = Transmit(TransmitOptions(
        baseUrl: 'http://localhost',
        uidGenerator: () => '1',
        eventSourceFactory: (url, {withCredentials}) {
          eventSource = FakeEventSource(url, withCredentials: withCredentials);
          return eventSource!;
        },
        httpClientFactory: (baseUrl, uid) {
          httpClient = FakeHttpClient(baseUrl: baseUrl, uid: uid);
          return httpClient!;
        },
      ));

      transmit.subscription('channel1');
      transmit.subscription('channel2');

      // Simulate latency
      await Future.delayed(const Duration(milliseconds: 100));

      expect(httpClient?.sentRequests.length, equals(0));

      eventSource?.sendErrorEvent();
      eventSource?.sendOpenEvent();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(httpClient?.sentRequests.length, equals(0));
    });

    test('should re-connect only created subscription', () async {
      FakeEventSource? eventSource;
      FakeHttpClient? httpClient;

      final transmit = Transmit(TransmitOptions(
        baseUrl: 'http://localhost',
        uidGenerator: () => '1',
        eventSourceFactory: (url, {withCredentials}) {
          eventSource = FakeEventSource(url, withCredentials: withCredentials);
          return eventSource!;
        },
        httpClientFactory: (baseUrl, uid) {
          httpClient = FakeHttpClient(baseUrl: baseUrl, uid: uid);
          return httpClient!;
        },
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      final subscription = transmit.subscription('channel1');
      transmit.subscription('channel2');

      await subscription.create();

      // Simulate latency
      await Future.delayed(const Duration(milliseconds: 100));

      expect(httpClient?.sentRequests.length, equals(1));

      eventSource?.sendErrorEvent();
      eventSource?.sendOpenEvent();

      await Future.delayed(const Duration(milliseconds: 200));

      expect(httpClient?.sentRequests.length, equals(2));
    });
  });
}

