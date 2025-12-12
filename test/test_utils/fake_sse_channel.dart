/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:async';
import 'package:transmit_client/src/transmit_io.dart';

/// Fake EventSource for testing.
/// This implements the EventSource interface used by the Transmit client.
class FakeEventSource {
  final StreamController<MessageEvent> _messageController =
      StreamController<MessageEvent>.broadcast();
  final StreamController<void> _openController = StreamController<void>.broadcast();
  final StreamController<void> _errorController = StreamController<void>.broadcast();
  final Completer<void> _readyCompleter = Completer<void>();
  final Uri _url;
  bool _isOpen = false;
  bool _closed = false;

  FakeEventSource(this._url, {bool withCredentials = false}) {
    // Simulate the channel opening
    Future.microtask(() {
      if (!_closed) {
        _isOpen = true;
        if (!_readyCompleter.isCompleted) {
          _readyCompleter.complete();
        }
        _openController.add(null);
      }
    });
  }

  Stream<MessageEvent> get stream => _messageController.stream;
  Stream<void> get onOpen => _openController.stream;
  Stream<void> get onError => _errorController.stream;
  Future<void> get ready => _readyCompleter.future;

  /// Emit a message event.
  void emitMessage(String data, {String? event, String? id}) {
    if (!_closed) {
      _messageController.add(MessageEvent(data: data, event: event, id: id));
    }
  }

  /// Send an open event.
  void sendOpenEvent() {
    if (_closed) return;
    _isOpen = true;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
    _openController.add(null);
  }

  /// Send an error event.
  void sendErrorEvent() {
    if (_closed) return;
    _errorController.add(null);
  }

  /// Send a close event.
  void sendCloseEvent() {
    if (_closed) return;
    _isOpen = false;
    _errorController.add(null);
  }

  /// Get the URL used to create this EventSource.
  Uri get url => _url;

  /// Check if the EventSource is open.
  bool get isOpen => _isOpen;

  /// Close the EventSource.
  void close() {
    _closed = true;
    _isOpen = false;
    _messageController.close();
    _openController.close();
    _errorController.close();
  }
}
