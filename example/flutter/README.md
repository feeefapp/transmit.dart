# Flutter Example

A simple, complete Flutter example demonstrating the AdonisJS Transmit Client with Stream API.

## Features

- ✅ Real-time message display
- ✅ Connection status indicator
- ✅ Stream API integration
- ✅ Automatic reconnection
- ✅ Clean UI with Material Design 3

## Running the Example

### Prerequisites

1. Make sure you have Flutter installed:
   ```bash
   flutter --version
   ```

2. Make sure the AdonisJS server is running at `http://localhost:3333`

### Steps

1. Navigate to the example directory:
   ```bash
   cd transmit-dart/example/flutter
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

   Or run on a specific device:
   ```bash
   flutter run -d chrome        # Web
   flutter run -d macos         # macOS
   flutter run -d windows       # Windows
   flutter run -d linux         # Linux
   flutter run -d <device-id>   # Mobile device
   ```

## Testing

1. Once the app is running and connected, you can trigger test events:
   ```bash
   curl http://localhost:3333/test
   ```

2. Messages will appear in real-time in the app.

## Code Highlights

### Stream API Usage

```dart
// Listen to messages using Stream API
_streamSubscription = _subscription!.stream.listen(
  (message) {
    setState(() {
      _messages.insert(0, message.toString());
    });
  },
  onError: (error) {
    // Handle errors
  },
);
```

### Connection Management

```dart
// Create client
_transmit = Transmit(TransmitOptions(
  baseUrl: 'http://localhost:3333',
));

// Listen to connection events
_transmit!.on('connected', () {
  setState(() {
    _status = 'Connected';
  });
});
```

### Cleanup

```dart
@override
void dispose() {
  _streamSubscription?.cancel();
  _transmit?.close();
  super.dispose();
}
```

## Notes

- The example uses the Stream API (recommended for Flutter)
- Messages are displayed in reverse order (newest first)
- Connection status is shown with color coding (green = connected, red = disconnected)
- The app automatically connects on startup
- Proper cleanup is performed in `dispose()` method

