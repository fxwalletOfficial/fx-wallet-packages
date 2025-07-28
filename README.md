# fx-wallet-packages

A collection of open source Dart/Flutter packages used in the [FxWallet](https://www.fxwallet.com) app.
These packages are modular, independently maintained, and can be reused in any Web3 Flutter application.

> 📦 All packages in this repo are published individually on [pub.dev](https://pub.dev/), and actively maintained.

---

## 📂 Repository Structure

```bash
fx-wallet-packages/
├── packages/
│   ├── k_chart_flutter/         # Interactive candle & line charts for crypto assets
│   ├── flutter_web3_webview/    # Web3 WebView bridge for dApp integration
│   ├── crypto_utils/            # General crypto utilities: hash, sign, encode
│   └── bc_ur_dart/              # UR (Uniform Resources) encoding/decoding for QR sharing
├── examples/
│   └── chart_demo_app/          # (Optional) Demo app showing k_chart_flutter usage
├── melos.yaml                   # (Optional) Melos workspace config for multi-package management
└── README.md
````

---

## 📦 Included Packages

| Package                                                                 | Pub.dev | Description                                           |
| ----------------------------------------------------------------------- | ------- | ----------------------------------------------------- |
| [`k_chart_flutter`](https://pub.dev/packages/k_chart_flutter)           | ✅       | Candlestick & line chart library optimized for crypto |
| [`flutter_web3_webview`](https://pub.dev/packages/flutter_web3_webview) | ✅       | Inject Web3 provider into WebView for dApp support    |
| [`crypto_utils`](https://pub.dev/packages/crypto_utils)                 | ✅       | Cryptographic tools (ECDSA, hashing, encoding)        |
| [`bc_ur_dart`](https://pub.dev/packages/bc_ur_dart)                     | ✅       | Dart implementation of the BC-UR protocol             |

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
