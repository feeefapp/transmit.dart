# Web Test Page

This directory contains a web-based test page for the Transmit client.

## Running the Test Page

### Option 1: Using `dart run` (Recommended)

```bash
cd transmit-dart
dart run -d chrome web/main.dart
```

This will automatically compile and open the page in Chrome.

### Option 2: Manual Compilation

1. Compile the Dart code to JavaScript:
   ```bash
   cd transmit-dart
   dart compile js web/main.dart -o web/main.dart.js
   ```

2. Serve the files using a local server:
   ```bash
   # Using Python
   python3 -m http.server 8080
   
   # Or using Node.js
   npx http-server -p 8080
   ```

3. Open `http://localhost:8080/web/index.html` in your browser

### Option 3: Using webdev (if available)

```bash
cd transmit-dart
dart pub global activate webdev
webdev serve web:8080
```

Then open `http://localhost:8080/index.html`

## Features

- ✅ Real-time connection status
- ✅ Automatic connection on page load
- ✅ Manual connect/disconnect controls
- ✅ Trigger test events button
- ✅ Message display with timestamps
- ✅ Clear messages functionality
- ✅ **Stream API examples** - Demonstrates both Stream and Callback APIs
- ✅ **Typed streams** - Shows how to use `streamAs<T>()` for type-safe message handling

## Testing

1. Make sure the AdonisJS server is running at `http://localhost:3333`
2. Open the test page
3. The page will automatically connect
4. Click "Trigger Test Event" to send a test event
5. Or use `curl http://localhost:3333/test` from terminal
6. Messages will appear in real-time in the messages area

