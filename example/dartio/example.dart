/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'package:transmit_client/transmit.dart';

Future<void> main() async {
  // Create a Transmit client
  final transmit = Transmit(TransmitOptions(
    baseUrl: 'http://localhost:3333',
    maxReconnectAttempts: 5,
    onReconnectAttempt: (attempt) {
      print('Reconnect attempt $attempt');
    },
  ));

  // Listen to connection events
  transmit.on('connected', () {
    print('Connected to server');
  });

  transmit.on('disconnected', () {
    print('Disconnected from server');
  });

  transmit.on('reconnecting', () {
    print('Reconnecting...');
  });

  // Create a subscription
  final subscription = transmit.subscription('test');

  // Register message handlers
  final unsubscribe = subscription.onMessage((message) {
    print('Message received: $message');
  });

  // Create the subscription on the server
  await subscription.create();
  print('Subscription created');

  // Wait a bit to receive messages
  await Future.delayed(const Duration(seconds: 30));

  // Remove handler
  unsubscribe();

  // Unsubscribe from server
  await subscription.delete();
  print('Subscription deleted');

  // Close connection
  transmit.close();
}


