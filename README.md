# AdonisJS Transmit Client (Dart)

A Dart client for the native Server-Sent-Event (SSE) module of AdonisJS. This package provides a simple and powerful API to receive real-time events from AdonisJS Transmit servers.

Working on both Dart VM (dart:io) and Web (dart:web).

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Creating a Client](#creating-a-client)
  - [Subscribing to Channels](#subscribing-to-channels)
  - [Listening to Messages](#listening-to-messages)
  - [Unsubscribing](#unsubscribing)
  - [Connection Events](#connection-events)
- [API Reference](#api-reference)
  - [Transmit Class](#transmit-class)
  - [TransmitOptions](#transmitoptions)
  - [Subscription Class](#subscription-class)
  - [TransmitStatus](#transmitstatus)
  - [SubscriptionStatus](#subscriptionstatus)
- [Advanced Usage](#advanced-usage)
  - [Custom UID Generation](#custom-uid-generation)
  - [Reconnection Handling](#reconnection-handling)
  - [Request Hooks](#request-hooks)
  - [Testing](#testing)
- [Platform Support](#platform-support)
- [Examples](#examples)
- [License](#license)

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  transmit_client:
    git:
      url: https://github.com/adonisjs/transmit-client
      path: transmit-dart
```

Or if published to pub.dev:

```yaml
dependencies:
  transmit_client: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:transmit_client/transmit.dart';

void main() async {
  // Create a Transmit client
  final transmit = Transmit(TransmitOptions(
    baseUrl: 'http://localhost:3333',
  ));

  // Wait for connection
  transmit.on('connected', () {
    print('Connected to server');
  });

  // Create a subscription
  final subscription = transmit.subscription('chat/1');

  // Listen for messages
  subscription.onMessage((message) {
    print('Received: $message');
  });

  // Register the subscription on the server
  await subscription.create();
}
```

## Usage

### Creating a Client

The `Transmit` class is the main entry point for connecting to an AdonisJS Transmit server.

```dart
final transmit = Transmit(TransmitOptions(
  baseUrl: 'http://localhost:3333',
));
```

The client automatically connects to the server when instantiated. The connection URL is constructed as `${baseUrl}/__transmit/events?uid=${uid}`.

### Subscribing to Channels

Use the `subscription` method to create or get a subscription to a channel:

```dart
final subscription = transmit.subscription('chat/1');
```

The `subscription` method returns a `Subscription` instance. If a subscription for the channel already exists, it returns the existing one.

To register the subscription on the server, call `create()`:

```dart
await subscription.create();
```

**Note:** The subscription must be created on the server before it can receive messages. However, you can register message handlers before or after calling `create()`.

### Listening to Messages

Use `onMessage` to register a handler that will be called whenever a message is received on the channel:

```dart
subscription.onMessage((message) {
  print('Message received: $message');
});
```

You can register multiple handlers on the same subscription:

```dart
subscription.onMessage((message) {
  print('Handler 1: $message');
});

subscription.onMessage((message) {
  print('Handler 2: $message');
});
```

All registered handlers will be called when a message is received.

#### One-Time Handlers

Use `onMessageOnce` to register a handler that will only be called once:

```dart
subscription.onMessageOnce((message) {
  print('This will only be called once');
});
```

After the handler is called, it's automatically removed from the subscription.

#### Typed Messages

You can specify the message type for better type safety:

```dart
subscription.onMessage<Map<String, dynamic>>((message) {
  print('User: ${message['user']}');
  print('Text: ${message['text']}');
});
```

### Unsubscribing

#### Removing a Message Handler

The `onMessage` method returns a function that you can call to remove the handler:

```dart
final unsubscribe = subscription.onMessage((message) {
  print('Message received');
});

// Later, remove the handler
unsubscribe();
```

#### Removing a Subscription from the Server

To completely remove the subscription from the server:

```dart
await subscription.delete();
```

After calling `delete()`, the subscription will no longer receive messages from the server.

#### Closing the Connection

To close the entire connection and clean up all resources:

```dart
transmit.close();
```

This will:
- Close the SSE connection
- Cancel all subscriptions
- Clean up all resources

### Connection Events

The `Transmit` class emits events that you can listen to:

```dart
// Listen for connection
transmit.on('connected', () {
  print('Connected to server');
});

// Listen for disconnection
transmit.on('disconnected', () {
  print('Disconnected from server');
});

// Listen for reconnection attempts
transmit.on('reconnecting', () {
  print('Reconnecting...');
});
```

The `on` method returns a `StreamSubscription` that you can cancel:

```dart
final subscription = transmit.on('connected', () {
  print('Connected');
});

// Later, stop listening
subscription.cancel();
```

## API Reference

### Transmit Class

The main client class for connecting to AdonisJS Transmit servers.

#### Constructor

```dart
Transmit(TransmitOptions options)
```

Creates a new Transmit client and automatically connects to the server.

#### Properties

- `String uid` - The unique identifier for this client instance

#### Methods

- `Subscription subscription(String channel)` - Create or get a subscription for a channel
- `StreamSubscription<TransmitStatus> on(String event, void Function() callback)` - Listen to connection events
- `void close()` - Close the connection and clean up resources

#### Events

- `'connected'` - Emitted when the connection is established
- `'disconnected'` - Emitted when the connection is lost
- `'reconnecting'` - Emitted when attempting to reconnect

### TransmitOptions

Configuration options for the Transmit client.

```dart
class TransmitOptions {
  final String baseUrl;                              // Required: Server base URL
  final String Function()? uidGenerator;            // Optional: Custom UID generator
  final dynamic Function(Uri, {bool withCredentials})? eventSourceFactory; // Optional: For testing
  final HttpClient Function(String, String)? httpClientFactory; // Optional: For testing
  final void Function(http.Request)? beforeSubscribe; // Optional: Hook before subscribe
  final void Function(http.Request)? beforeUnsubscribe; // Optional: Hook before unsubscribe
  final int? maxReconnectAttempts;                  // Optional: Max reconnect attempts (default: 5)
  final void Function(int)? onReconnectAttempt;      // Optional: Called on each reconnect attempt
  final void Function()? onReconnectFailed;         // Optional: Called when reconnection fails
  final void Function(http.Response)? onSubscribeFailed; // Optional: Called when subscription fails
  final void Function(String)? onSubscription;       // Optional: Called when subscription succeeds
  final void Function(String)? onUnsubscription;    // Optional: Called when unsubscription succeeds
}
```

#### Options

- **`baseUrl`** (required): The base URL of the AdonisJS server (e.g., `'http://localhost:3333'`)
- **`uidGenerator`**: Custom function to generate unique client IDs. Defaults to UUID v4
- **`maxReconnectAttempts`**: Maximum number of reconnection attempts. Defaults to `5`
- **`onReconnectAttempt`**: Callback called on each reconnection attempt with the attempt number
- **`onReconnectFailed`**: Callback called when all reconnection attempts have failed
- **`onSubscribeFailed`**: Callback called when a subscription request fails
- **`onSubscription`**: Callback called when a subscription is successfully created
- **`onUnsubscription`**: Callback called when a subscription is successfully removed
- **`beforeSubscribe`**: Hook called before sending a subscribe request. Can modify the request
- **`beforeUnsubscribe`**: Hook called before sending an unsubscribe request. Can modify the request

### Subscription Class

Represents a subscription to a channel.

#### Properties

- `bool isCreated` - Returns `true` if the subscription is created on the server
- `bool isDeleted` - Returns `true` if the subscription has been deleted
- `int handlerCount` - Returns the number of registered message handlers

#### Methods

- `Future<void> create()` - Create the subscription on the server (idempotent)
- `Future<void> delete()` - Remove the subscription from the server
- `void Function() onMessage<T>(void Function(T) handler)` - Register a message handler. Returns an unsubscribe function
- `void onMessageOnce<T>(void Function(T) handler)` - Register a one-time message handler

### TransmitStatus

Enum representing the connection status of the client.

```dart
enum TransmitStatus {
  initializing,  // Client is being initialized
  connecting,   // Attempting to connect to the server
  connected,    // Successfully connected to the server
  disconnected, // Connection lost
  reconnecting, // Attempting to reconnect
}
```

### SubscriptionStatus

Enum representing the status of a subscription.

```dart
enum SubscriptionStatus {
  pending(0),  // Subscription is pending (not yet created on server)
  created(1),  // Subscription is created on the server
  deleted(2),  // Subscription is deleted (unsubscribed from server)
}
```

## Advanced Usage

### Custom UID Generation

By default, the client uses UUID v4 to generate unique identifiers. You can provide a custom generator:

```dart
final transmit = Transmit(TransmitOptions(
  baseUrl: 'http://localhost:3333',
  uidGenerator: () => 'custom-${DateTime.now().millisecondsSinceEpoch}',
));
```

### Reconnection Handling

The client automatically reconnects when the connection is lost. You can customize the reconnection behavior:

```dart
final transmit = Transmit(TransmitOptions(
  baseUrl: 'http://localhost:3333',
  maxReconnectAttempts: 10,
  onReconnectAttempt: (attempt) {
    print('Reconnect attempt $attempt');
  },
  onReconnectFailed: () {
    print('Failed to reconnect after all attempts');
  },
));
```

When the connection is lost:
1. The client enters `reconnecting` status
2. It attempts to reconnect with exponential backoff
3. All existing subscriptions are automatically re-registered on successful reconnection
4. If all attempts fail, `onReconnectFailed` is called

### Request Hooks

You can modify subscription requests before they're sent:

```dart
final transmit = Transmit(TransmitOptions(
  baseUrl: 'http://localhost:3333',
  beforeSubscribe: (request) {
    // Add custom headers
    request.headers['Authorization'] = 'Bearer token';
    request.headers['X-Custom-Header'] = 'value';
  },
  beforeUnsubscribe: (request) {
    // Modify unsubscribe request
    print('Unsubscribing from channel');
  },
));
```

### Testing

The package provides factory functions for testing:

```dart
// Create a fake event source for testing
final fakeEventSource = FakeEventSource();

final transmit = Transmit(TransmitOptions(
  baseUrl: 'http://localhost:3333',
  eventSourceFactory: (uri, {withCredentials}) => fakeEventSource,
  httpClientFactory: (baseUrl, uid) => FakeHttpClient(),
));
```

See the test files in the `test/` directory for examples of testing with mocks.

## Platform Support

The package automatically selects the appropriate implementation based on the platform:

- **Web (dart:html / Flutter Web)**: Uses native `EventSource` API with full support for XSRF token retrieval from cookies
- **Dart VM (dart:io)**: Uses HTTP-based SSE parsing for CLI applications and servers
- **Flutter Mobile/Desktop (Android/iOS/macOS/Windows/Linux)**: Uses HTTP-based SSE parsing
  - **Android**: Ensure internet permission is granted in `AndroidManifest.xml`
  - **iOS**: May require network security configuration for non-HTTPS connections
  - All platforms: The correct implementation is automatically selected via conditional imports

### Platform-Specific Notes

#### Web Platform

On web platforms, the client automatically retrieves XSRF tokens from cookies. The token is sent in the `X-XSRF-TOKEN` header with all requests.

#### Dart IO Platform

On `dart:io` platforms, the client manually parses Server-Sent Events from HTTP streams. This works for:
- CLI applications
- Server-side Dart applications
- Flutter mobile/desktop applications

The client automatically sets the following request headers for optimal SSE performance:
- `Accept: text/event-stream`
- `Cache-Control: no-cache, no-transform`
- `Connection: keep-alive`

### SSE Anti-Buffering Headers

For optimal real-time event delivery, your server should send the following response headers:

```
Content-Type: text/event-stream
Cache-Control: no-cache, no-transform
Connection: keep-alive
X-Accel-Buffering: no  # Important for Nginx proxies
```

#### Web Platform (Browser)

**Important**: The browser's `EventSource` API does not allow setting custom request headers. The server **must** send these headers in the response. This is a browser security limitation.

#### Dart IO Platform

The client automatically sets appropriate request headers (`Accept`, `Cache-Control`, `Connection`). However, the server should still send the response headers listed above, especially `X-Accel-Buffering: no` if you're behind an Nginx proxy.

**Nginx Configuration**: If using Nginx as a reverse proxy, ensure buffering is disabled:

```nginx
location /__transmit/events {
  proxy_pass http://your_backend;
  proxy_buffering off;
  proxy_cache off;
  proxy_read_timeout 24h;
}
```

## Examples

### Basic Example

```dart
import 'package:transmit_client/transmit.dart';

void main() async {
  final transmit = Transmit(TransmitOptions(
    baseUrl: 'http://localhost:3333',
  ));

  transmit.on('connected', () {
    print('Connected');
  });

  final subscription = transmit.subscription('notifications');
  
  subscription.onMessage((message) {
    print('Notification: $message');
  });

  await subscription.create();
  
  // Keep the app running
  await Future.delayed(Duration(minutes: 10));
  
  await subscription.delete();
  transmit.close();
}
```

### Multiple Channels

```dart
final transmit = Transmit(TransmitOptions(
  baseUrl: 'http://localhost:3333',
));

// Subscribe to multiple channels
final chatSubscription = transmit.subscription('chat/1');
final notificationsSubscription = transmit.subscription('notifications');

chatSubscription.onMessage((message) {
  print('Chat: $message');
});

notificationsSubscription.onMessage((message) {
  print('Notification: $message');
});

await Future.wait([
  chatSubscription.create(),
  notificationsSubscription.create(),
]);
```

### Typed Messages

```dart
// Define your message type
class ChatMessage {
  final String user;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.user,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      user: json['user'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

// Use typed handlers
final subscription = transmit.subscription('chat/1');

subscription.onMessage<Map<String, dynamic>>((json) {
  final message = ChatMessage.fromJson(json);
  print('${message.user}: ${message.text}');
});
```

### Error Handling

```dart
final transmit = Transmit(TransmitOptions(
  baseUrl: 'http://localhost:3333',
  onSubscribeFailed: (response) {
    print('Subscription failed: ${response.statusCode}');
  },
  onReconnectFailed: () {
    print('Failed to reconnect. Please check your connection.');
  },
));

try {
  final subscription = transmit.subscription('test');
  await subscription.create();
} catch (e) {
  print('Error: $e');
}
```

### Flutter Example

```dart
import 'package:flutter/material.dart';
import 'package:transmit_client/transmit.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Transmit _transmit;
  late Subscription _subscription;
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _transmit = Transmit(TransmitOptions(
      baseUrl: 'http://localhost:3333',
    ));
    
    _subscription = _transmit.subscription('chat/1');
    _subscription.onMessage((message) {
      setState(() {
        _messages.add(message.toString());
      });
    });
    
    _subscription.create();
  }

  @override
  void dispose() {
    _transmit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(_messages[index]));
        },
      ),
    );
  }
}
```

## License

MIT
