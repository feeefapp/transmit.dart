/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/// Status of a subscription.
enum SubscriptionStatus {
  /// Subscription is pending (not yet created on server).
  pending(0),

  /// Subscription is created on the server.
  created(1),

  /// Subscription is deleted (unsubscribed from server).
  deleted(2);

  const SubscriptionStatus(this.value);
  final int value;
}


