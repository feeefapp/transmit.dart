/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation using EventSource API.
/// This replaces EventSourceStub when running on web.
class EventSourceWeb {
  final web.EventSource _eventSource;
  final StreamController<MessageEvent> _messageController =
      StreamController<MessageEvent>.broadcast();
  final StreamController<void> _openController = StreamController<void>.broadcast();
  final StreamController<void> _errorController = StreamController<void>.broadcast();
  final Completer<void> _readyCompleter = Completer<void>();

  EventSourceWeb(Uri url, {bool withCredentials = false})
      : _eventSource = web.EventSource(url.toString(), web.EventSourceInit(withCredentials: withCredentials)) {
    _eventSource.addEventListener('message', ((web.Event event) {
      final messageEvent = event as web.MessageEvent;
      _messageController.add(MessageEvent(
        data: messageEvent.data?.toString() ?? '',
        event: messageEvent.type,
        id: null,
      ));
    }).toJS);

    _eventSource.addEventListener('open', ((web.Event event) {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      _openController.add(null);
    }).toJS);

    _eventSource.addEventListener('error', ((web.Event event) {
      _errorController.add(null);
    }).toJS);
  }

  Stream<MessageEvent> get stream => _messageController.stream;
  Stream<void> get onOpen => _openController.stream;
  Stream<void> get onError => _errorController.stream;
  Future<void> get ready => _readyCompleter.future;

  void close() {
    _eventSource.close();
    _messageController.close();
    _openController.close();
    _errorController.close();
  }
}

/// Message event wrapper for web platform.
class MessageEvent {
  final String? data;
  final String? event;
  final String? id;

  MessageEvent({this.data, this.event, this.id});
}

/// Export EventSourceWeb as EventSourceStub for conditional imports.
typedef EventSourceStub = EventSourceWeb;

