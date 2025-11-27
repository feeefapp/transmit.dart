/*
 * transmit_client
 *
 * (c) mohamed lounnas <mohamad@feeef.org>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import 'package:http/http.dart' as http;
import 'hook_event.dart';

/// Hook system for lifecycle events.
class Hook {
  final _handlers = <HookEvent, Set<Function>>{};

  /// Register a handler for a specific hook event.
  Hook register(HookEvent event, Function handler) {
    _handlers.putIfAbsent(event, () => <Function>{}).add(handler);
    return this;
  }

  /// Trigger beforeSubscribe handlers.
  Hook beforeSubscribe(http.Request request) {
    _handlers[HookEvent.beforeSubscribe]?.forEach((handler) {
      handler(request);
    });
    return this;
  }

  /// Trigger beforeUnsubscribe handlers.
  Hook beforeUnsubscribe(http.Request request) {
    _handlers[HookEvent.beforeUnsubscribe]?.forEach((handler) {
      handler(request);
    });
    return this;
  }

  /// Trigger onReconnectAttempt handlers.
  Hook onReconnectAttempt(int attempt) {
    _handlers[HookEvent.onReconnectAttempt]?.forEach((handler) {
      handler(attempt);
    });
    return this;
  }

  /// Trigger onReconnectFailed handlers.
  Hook onReconnectFailed() {
    _handlers[HookEvent.onReconnectFailed]?.forEach((handler) {
      handler();
    });
    return this;
  }

  /// Trigger onSubscribeFailed handlers.
  Hook onSubscribeFailed(http.Response response) {
    _handlers[HookEvent.onSubscribeFailed]?.forEach((handler) {
      handler(response);
    });
    return this;
  }

  /// Trigger onSubscription handlers.
  Hook onSubscription(String channel) {
    _handlers[HookEvent.onSubscription]?.forEach((handler) {
      handler(channel);
    });
    return this;
  }

  /// Trigger onUnsubscription handlers.
  Hook onUnsubscription(String channel) {
    _handlers[HookEvent.onUnsubscription]?.forEach((handler) {
      handler(channel);
    });
    return this;
  }
}


