# fx-wallet-packages

A collection of open source Dart/Flutter packages used in the [FxWallet](https://www.fxwallet.com) app.
These packages are modular, independently maintained, and can be reused in any Web3 Flutter application.

> 📦 Packages are independently versioned and maintained. Each package's
> `pubspec.yaml` is the source of truth for its version and publication metadata.

---

## 📂 Repository Structure

```bash
fx-wallet-packages/
├── packages/
│   ├── k_chart_flutter/         # Interactive candle & line charts for crypto assets
│   ├── flutter_web3_webview/    # Web3 WebView bridge for dApp integration
│   ├── fx_push_client/          # APNs/FCM subscription and notification event client
│   ├── crypto_wallet_util/       # General cryptocurrency wallet utilities
│   ├── bc_ur_dart/              # UR (Uniform Resources) encoding/decoding for QR sharing
│   ├── aleo_dart/               # Aleo blockchain SDK (FFI to aleo_ffi)
│   └── aleo_flutter/            # Flutter integration for Aleo native artifacts
├── rust/
│   ├── aleo_ffi/                # Native Rust crate (clean-room, Apache-2.0) backing aleo_dart
│   └── vendor/                  # Vendored + patched snarkVM crates (Apache-2.0)
├── examples/
│   ├── bc_ur_dart_demo/         # BC-UR integration example
│   ├── k_chart_demo/            # k_chart_flutter integration example
│   └── web3_webview_demo/       # flutter_web3_webview integration example
├── melos.yaml                   # (Optional) Melos workspace config for multi-package management
└── README.md
```

---

## 📦 Included Packages

| Package | Description |
| --- | --- |
| [`k_chart_flutter`](packages/k_chart_flutter) | Candlestick and line chart library optimized for crypto |
| [`flutter_web3_webview`](packages/flutter_web3_webview) | Web3 provider bridge for in-app WebViews |
| [`fx_push_client`](packages/fx_push_client) | APNs/FCM subscription synchronization and notification event normalization |
| [`crypto_wallet_util`](packages/crypto_wallet_util) | Cryptocurrency wallet utilities |
| [`bc_ur_dart`](packages/bc_ur_dart) | BC-UR encoding and decoding |
| [`aleo_dart`](packages/aleo_dart) | Aleo blockchain Dart SDK backed by `aleo_ffi` |
| [`aleo_flutter`](packages/aleo_flutter) | Flutter integration for Aleo native artifacts |

---

## 📖 Usage

To use a package in your project, add it from [pub.dev](https://pub.dev), for example:

```yaml
dependencies:
  k_chart_flutter: ^x.y.z
```

Or, if using this repo locally as a monorepo (for development):

```yaml
dependencies:
  k_chart_flutter:
    path: ../packages/k_chart_flutter
```

---

## 🛠️ Development

This repo can be used as a Dart mono-repo. Recommended tools:

* [`melos`](https://melos.invertase.dev/): to manage and bootstrap multiple packages

```bash
dart pub global activate melos
melos bootstrap
```

---

## 🙌 Contributing

We welcome contributions and issues!
Each package has its own README and issue tracker. For questions or bugs, please open issues in the corresponding directory.

---

## 📜 License

MIT License. See [LICENSE](./LICENSE) for details.
