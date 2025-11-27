/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/// Hook events that can be registered.
class HookEvent {
  const HookEvent._(this.value);
  final String value;

  static const beforeSubscribe = HookEvent._('beforeSubscribe');
  static const beforeUnsubscribe = HookEvent._('beforeUnsubscribe');
  static const onReconnectAttempt = HookEvent._('onReconnectAttempt');
  static const onReconnectFailed = HookEvent._('onReconnectFailed');
  static const onSubscribeFailed = HookEvent._('onSubscribeFailed');
  static const onSubscription = HookEvent._('onSubscription');
  static const onUnsubscription = HookEvent._('onUnsubscription');
}


