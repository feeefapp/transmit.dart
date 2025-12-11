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
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'http_client.dart';
import 'hook.dart';
import 'hook_event.dart';
import 'subscription.dart';
import 'transmit_status.dart';
import 'transmit_stub.dart'
    if (dart.library.html) 'transmit_web.dart'
    if (dart.library.io) 'transmit_io.dart';

/// Options for creating a Transmit client.
class TransmitOptions {
  final String baseUrl;
  final String Function()? uidGenerator;
  final dynamic Function(Uri, {bool withCredentials})? eventSourceFactory;
  final HttpClient Function(String baseUrl, String uid)? httpClientFactory;
  final void Function(http.Request)? beforeSubscribe;
  final void Function(http.Request)? beforeUnsubscribe;
  final int? maxReconnectAttempts;
  final void Function(int)? onReconnectAttempt;
  final void Function()? onReconnectFailed;
  final void Function(http.Response)? onSubscribeFailed;
  final void Function(String)? onSubscription;
  final void Function(String)? onUnsubscription;

  TransmitOptions({
    required this.baseUrl,
    this.uidGenerator,
    this.eventSourceFactory,
    this.httpClientFactory,
    this.beforeSubscribe,
    this.beforeUnsubscribe,
    this.maxReconnectAttempts,
    this.onReconnectAttempt,
    this.onReconnectFailed,
    this.onSubscribeFailed,
    this.onSubscription,
    this.onUnsubscription,
  });
}

/// Main Transmit client class.
class Transmit {
  final String _uid;
  final TransmitOptions _options;
  final Map<String, Subscription> _subscriptions = {};
  late final HttpClient _httpClient;
  final Hook _hooks;
  TransmitStatus _status = TransmitStatus.initializing;
  dynamic _eventSource;
  StreamSubscription<MessageEvent>? _messageSubscription;
  StreamSubscription<void>? _openSubscription;
  StreamSubscription<void>? _errorSubscription;
  final StreamController<TransmitStatus> _statusController = StreamController<TransmitStatus>.broadcast();
  int _reconnectAttempts = 0;

  /// Returns the unique identifier of the client.
  String get uid => _uid;

  static final _uuid = Uuid();

  /// Create a new Transmit client.
  Transmit(TransmitOptions options)
      : _options = options,
        _uid = options.uidGenerator?.call() ?? _uuid.v4(),
        _hooks = Hook() {
    // Initialize HTTP client after _uid is set
    _httpClient =
        options.httpClientFactory?.call(options.baseUrl, _uid) ?? HttpClient(baseUrl: options.baseUrl, uid: _uid);
    // Register hooks
    if (options.beforeSubscribe != null) {
      _hooks.register(HookEvent.beforeSubscribe, options.beforeSubscribe!);
    }
    if (options.beforeUnsubscribe != null) {
      _hooks.register(HookEvent.beforeUnsubscribe, options.beforeUnsubscribe!);
    }
    if (options.onReconnectAttempt != null) {
      _hooks.register(HookEvent.onReconnectAttempt, options.onReconnectAttempt!);
    }
    if (options.onReconnectFailed != null) {
      _hooks.register(HookEvent.onReconnectFailed, options.onReconnectFailed!);
    }
    if (options.onSubscribeFailed != null) {
      _hooks.register(HookEvent.onSubscribeFailed, options.onSubscribeFailed!);
    }
    if (options.onSubscription != null) {
      _hooks.register(HookEvent.onSubscription, options.onSubscription!);
    }
    if (options.onUnsubscription != null) {
      _hooks.register(HookEvent.onUnsubscription, options.onUnsubscription!);
    }

    _connect();
  }

  /// Change the status and emit an event.
  void _changeStatus(TransmitStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Connect to the server.
  Future<void> _connect() async {
    _changeStatus(TransmitStatus.connecting);

    final url = Uri.parse('${_options.baseUrl}/__transmit/events').replace(queryParameters: {'uid': _uid});

    try {
      if (_options.eventSourceFactory != null) {
        _eventSource = _options.eventSourceFactory!(url, withCredentials: true);
      } else {
        // Use platform-specific EventSource (IO or Web)
        _eventSource = EventSourceStub(url, withCredentials: true);
      }

      // Wait for ready (for IO, this is async; for web, it's also async)
      await _eventSource.ready;

      _changeStatus(TransmitStatus.connected);
      _reconnectAttempts = 0;

      // Re-register all created subscriptions
      for (final subscription in _subscriptions.values) {
        if (subscription.isCreated) {
          await subscription.forceCreate();
        }
      }

      // Listen to messages
      _messageSubscription = _eventSource.stream.listen(
        _onMessage,
        onError: _onError,
        cancelOnError: false,
      );

      // Listen to open events
      _openSubscription = _eventSource.onOpen.listen((_) {
        _changeStatus(TransmitStatus.connected);
        _reconnectAttempts = 0;
      });

      // Listen to error events
      _errorSubscription = _eventSource.onError.listen((_) {
        _onError(null);
      });
    } catch (error) {
      _onError(error);
    }
  }

  /// Handle incoming messages.
  void _onMessage(MessageEvent event) {
    try {
      final eventData = event.data ?? '';
      if (eventData.isEmpty) {
        return;
      }

      final data = jsonDecode(eventData) as Map<String, dynamic>;
      final channel = data['channel'] as String?;
      final payload = data['payload'];

      if (channel == null) {
        return;
      }

      final subscription = _subscriptions[channel];
      if (subscription == null) {
        return;
      }

      subscription.$runHandler(payload);
    } catch (error) {
      // Error handling - silently ignore parsing errors
    }
  }

  /// Handle connection errors.
  void _onError(dynamic error) {
    if (_status != TransmitStatus.reconnecting) {
      _changeStatus(TransmitStatus.disconnected);
    }

    _changeStatus(TransmitStatus.reconnecting);

    _hooks.onReconnectAttempt(_reconnectAttempts + 1);

    final maxAttempts = _options.maxReconnectAttempts ?? 5;
    if (_reconnectAttempts >= maxAttempts) {
      _eventSource?.close();
      _hooks.onReconnectFailed();
      return;
    }

    _reconnectAttempts++;

    // Attempt to reconnect after a delay
    Future.delayed(Duration(milliseconds: 100 * _reconnectAttempts), () {
      if (_status == TransmitStatus.reconnecting) {
        _connect();
      }
    });
  }

  /// Create or get a subscription for a channel.
  Subscription subscription(String channel) {
    if (_subscriptions.containsKey(channel)) {
      return _subscriptions[channel]!;
    }

    final subscription = Subscription(SubscriptionOptions(
      channel: channel,
      httpClient: _httpClient,
      hooks: _hooks,
      getEventSourceStatus: () => _status,
    ));

    _subscriptions[channel] = subscription;
    return subscription;
  }

  /// Listen to status events.
  StreamSubscription<TransmitStatus> on(String event, void Function() callback) {
    if (event == 'connected') {
      return _statusController.stream.where((status) => status == TransmitStatus.connected).listen((_) => callback());
    } else if (event == 'disconnected') {
      return _statusController.stream
          .where((status) => status == TransmitStatus.disconnected)
          .listen((_) => callback());
    } else if (event == 'reconnecting') {
      return _statusController.stream
          .where((status) => status == TransmitStatus.reconnecting)
          .listen((_) => callback());
    }
    throw ArgumentError('Unknown event: $event');
  }

  /// Set headers that will be included in all HTTP requests.
  /// Useful for setting authentication headers when user logs in/out.
  /// [headers] - Map with header key-value pairs, or null to clear headers
  ///
  /// Example:
  /// ```dart
  /// // When user logs in
  /// transmit.setHeaders({
  ///   'Authorization': 'Bearer token-123',
  ///   'X-User-Id': '123'
  /// });
  ///
  /// // When user logs out
  /// transmit.setHeaders(null);
  /// ```
  void setHeaders(Map<String, String>? headers) {
    _httpClient.setHeaders(headers);
  }

  /// Get the current headers that are set via setHeaders.
  Map<String, String> getHeaders() {
    return _httpClient.getHeaders();
  }

  /// Close the connection.
  void close() {
    _messageSubscription?.cancel();
    _openSubscription?.cancel();
    _errorSubscription?.cancel();
    _eventSource?.close();
    _statusController.close();
  }
}
