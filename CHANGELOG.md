## 1.2.3

- Restores the 1.2.1 API that 1.2.2 dropped by mistake (it was built from an older tree):
  `TransmitOptions.heartbeatTimeout`, heartbeat monitoring, `Transmit.onMessage` and
  `Transmit.removeSubscription`. Keeps the 1.2.2 web fix. Use 1.2.3 instead of 1.2.2.

## 1.2.2

- Web: pick the EventSource and HTTP client implementations with `dart.library.js_interop`.
  `dart.library.html` is false under dart2wasm, so Flutter web builds with `--wasm` got the
  stub and never connected.
