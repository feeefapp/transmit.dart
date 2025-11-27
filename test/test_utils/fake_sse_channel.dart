/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'dart:async';
import 'package:sse_channel/sse_channel.dart';

/// Fake SSE channel for testing.
/// This is a minimal implementation that provides the interface needed for testing.
class FakeSseChannel implements SseChannel {
  final StreamController<MessageEvent> _streamController =
      StreamController<MessageEvent>.broadcast();
  final StreamController<String?> _sinkController = StreamController<String?>();
  final Completer<void> _readyCompleter = Completer<void>();
  final Uri _url;
  bool _isOpen = false;
  late final SseSink _sseSink;

  FakeSseChannel(this._url) {
    // Create a simple SseSink wrapper
    _sseSink = _FakeSseSink(_sinkController.sink);
    // Simulate the channel opening
    Future.microtask(() {
      _isOpen = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    });
  }

  @override
  Stream<MessageEvent> get stream => _streamController.stream;

  @override
  SseSink get sink => _sseSink;

  @override
  Future<void> get ready => _readyCompleter.future;

  /// Emit a message event.
  void emitMessage(String data, {String? event, String? id}) {
    _streamController.add(MessageEvent(data: data, event: event, id: id));
  }

  /// Send an open event.
  void sendOpenEvent() {
    _isOpen = true;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  /// Send a close event.
  void sendCloseEvent() {
    _isOpen = false;
    _streamController.addError(Exception('Connection closed'));
  }

  /// Get the URL used to create this channel.
  Uri get url => _url;

  /// Check if the channel is open.
  bool get isOpen => _isOpen;

  /// Close the channel.
  void close() {
    _streamController.close();
    _sinkController.close();
  }
}

/// Simple fake SseSink implementation.
class _FakeSseSink implements SseSink {
  final StreamSink<String?> _sink;

  _FakeSseSink(this._sink);

  @override
  Future<void> close() => _sink.close();

  @override
  void add(String? data) => _sink.add(data);

  @override
  Future<void> addStream(Stream<String?> stream) => _sink.addStream(stream);

  @override
  Future<void> get done => _sink.done;
}
