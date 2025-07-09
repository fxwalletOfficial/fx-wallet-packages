# flutter_web3_webview

A Flutter WebView widget that supports wallet connection to Web3 DApps. Supports both EVM and Solana chains.

## Features

- WalletConnect support
- EVM and Solana chain support
- Custom provider JS injection
- Ideal for DApp browsers and in-app Web3 scenarios

## Installation

```yaml
dependencies:
  flutter_web3_webview: ^0.1.5
```

## Quick Start

```dart
// Initialize provider JS asset before use
await Web3Webview.initJs();

// Use the Web3Webview
Web3Webview();
```

## Example

A full demo app is available at `examples/web3_webview_demo` in this repository. You can run and debug it locally.

## Contributing

Issues and PRs are welcome!

## License

MIT
