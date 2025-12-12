/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:async';
import 'package:transmit_client/transmit.dart';

Future<void> main() async {
  print('🚀 Transmit Client Example (Dart IO)\n');

  // Create a Transmit client
  final transmit = Transmit(TransmitOptions(
    baseUrl: 'http://localhost:3333',
    maxReconnectAttempts: 5,
    onReconnectAttempt: (attempt) {
      print('⚠️  Reconnect attempt $attempt');
    },
    onReconnectFailed: () {
      print('❌ Reconnect failed');
    },
  ));

  // Listen to connection events using Stream
  transmit.on('connected', () {
    print('✅ Connected to server');
    print('   UID: ${transmit.uid}\n');
  });

  transmit.on('disconnected', () {
    print('❌ Disconnected from server');
  });

  transmit.on('reconnecting', () {
    print('🔄 Reconnecting...');
  });

  // Create a subscription
  final subscription = transmit.subscription('test');

  print('📡 Using Stream API (recommended):');
  print('─' * 50);

  // Example 1: Basic stream listening
  final streamSubscription = subscription.stream.listen(
    (message) {
      print('📨 Message received: $message');
    },
    onError: (error) {
      print('❌ Stream error: $error');
    },
    onDone: () {
      print('✅ Stream closed');
    },
  );

  // Example 2: Typed stream with transformation
  subscription.streamAs<Map<String, dynamic>>()
    .where((msg) => msg.containsKey('type'))
    .map((msg) => '${msg['type']}: ${msg['data'] ?? 'N/A'}')
    .listen((formatted) {
      print('📝 Formatted: $formatted');
    });

  // Example 3: Take first 5 messages
  subscription.stream.take(5).listen((message) {
    print('🎯 First 5 messages: $message');
  });

  print('\n📡 Using Callback API (also available):');
  print('─' * 50);

  // Callback API still works for compatibility
  final unsubscribe = subscription.onMessage((message) {
    print('📞 Callback received: $message');
  });

  // Create the subscription on the server
  print('\n🔌 Creating subscription...');
  await subscription.create();
  print('✅ Subscription created for channel: test\n');

  print('⏳ Waiting for messages (30 seconds)...');
  print('   Send GET request to http://localhost:3333/test to trigger events\n');

  // Wait to receive messages
  await Future.delayed(const Duration(seconds: 30));

  print('\n🧹 Cleaning up...');
  
  // Cancel stream subscription
  await streamSubscription.cancel();
  
  // Remove callback handler
  unsubscribe();

  // Unsubscribe from server
  await subscription.delete();
  print('✅ Subscription deleted');

  // Close connection
  transmit.close();
  print('✅ Connection closed');
}
