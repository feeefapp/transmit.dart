/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/// Connection status of the Transmit client.
enum TransmitStatus {
  /// Client is being initialized.
  initializing,

  /// Attempting to connect to the server.
  connecting,

  /// Successfully connected to the server.
  connected,

  /// Connection lost.
  disconnected,

  /// Attempting to reconnect.
  reconnecting,
}


