/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:async';

/// Stub for EventSource - will be replaced by platform-specific implementations.
/// This is the default that throws an error, but conditional imports will replace it.
class EventSourceStub {
  final StreamController<MessageEvent> _messageController =
      StreamController<MessageEvent>.broadcast();
  final StreamController<void> _openController = StreamController<void>.broadcast();
  final StreamController<void> _errorController = StreamController<void>.broadcast();
  final Completer<void> _readyCompleter = Completer<void>();

  EventSourceStub(Uri url, {bool withCredentials = false});

  Stream<MessageEvent> get stream => _messageController.stream;
  Stream<void> get onOpen => _openController.stream;
  Stream<void> get onError => _errorController.stream;
  Future<void> get ready => _readyCompleter.future;

  void close() {
    _messageController.close();
    _openController.close();
    _errorController.close();
  }
}

/// Message event wrapper.
class MessageEvent {
  final String? data;
  final String? event;
  final String? id;

  MessageEvent({this.data, this.event, this.id});
}

