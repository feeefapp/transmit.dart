## 1.2.2

- Web: pick the EventSource and HTTP client implementations with `dart.library.js_interop`.
  `dart.library.html` is false under dart2wasm, so Flutter web builds with `--wasm` got the
  stub and never connected.
