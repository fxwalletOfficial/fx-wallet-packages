# web3_webview_demo

End-to-end demo / regression-test bed for the
[`flutter_web3_webview`](../../packages/flutter_web3_webview) package.

The goal is twofold:

1. **Showcase** every callback `Web3Webview` exposes, against a curated
   set of real-world DApps (Uniswap, OpenSea, Jupiter, Magic Eden, …) so
   anyone integrating the package can copy a working setup.
2. **Manual regression bed** for the FxWallet team — change the JS
   bundle or the Dart dispatcher, then click through the bookmark grid
   to confirm `connect` / `personal_sign` / `eth_signTypedData_v4` /
   `eth_sendTransaction` / `wallet_switchEthereumChain` / Solana
   `signMessage` / `signTransaction` all still resolve cleanly.

## Status

The demo lands incrementally — each phase is its own PR off the
`epic/flutter-web3-webview-hardening` branch so the diff stays small and
reviewable.

| Phase | What it adds | Status |
|------:|--------------|--------|
| **1** | App shell + zero-dep state mgmt + bookmark grid + chain / account pickers (placeholders for signing / approval / log) | ✅ this commit |
| 2 | Bookmark grid polish, custom-URL entry, recent-DApp memory | ☐ |
| 3 | Full `Web3Webview` callback wiring + approval bottom-sheet + bridge log capture | ☐ |
| 4 | EVM signing (`web3dart`): `personal_sign`, `eth_signTypedData_v3/v4`, `eth_sendTransaction` (mock hash by default, real broadcast on toggle) | ☐ |
| 5 | Solana signing (`cryptography` + `bs58`): `solana_signMessage`, `solana_signTransaction` | ☐ |
| 6 | Settings: auto-approve toggle, real-broadcast toggle, bridge-log viewer | ☐ |
| 7 | README screenshots, manual regression checklist, more widget tests | ☐ |

## Run it

```bash
cd examples/web3_webview_demo
flutter pub get
flutter run
```

The demo depends on the local `flutter_web3_webview` package via a path
override in `pubspec_overrides.yaml`, so any change to the package source
is picked up by the next hot restart.

## Test accounts

The Phase 4 / 5 signing implementations derive their keys from the
well-known development mnemonic

    test test test test test test test test test test test junk

(BIP-44 path `m/44'/60'/0'/0/<i>` for EVM, `m/44'/501'/<i>'/0'` for
Solana). The mnemonic is intentionally public — **anything sent to these
addresses is immediately swept by bots that scan for the phrase**. Never
fund them.

## Architecture

```
lib/
├── main.dart            # entrypoint — Web3Webview.initJs() + runApp
├── app.dart             # MaterialApp + named routes + service scopes
├── data/
│   ├── chains.dart      # EVM chains + Solana clusters catalogue
│   └── dapps.dart       # bookmark catalogue grouped by category
├── services/
│   ├── wallet_state.dart # ChangeNotifier — active account / chain / settings
│   └── bridge_log.dart   # ring-buffer log of bridge round-trips
├── pages/
│   ├── home_page.dart   # bookmark grid + active-identity card
│   ├── browser_page.dart # Web3Webview + AppBar chain / account chips
│   └── settings_page.dart # account / chain picker + (pending) toggles
└── widgets/             # filled in by Phase 3+
```

State propagates through `InheritedNotifier`-backed scopes
(`WalletStateScope`, `BridgeLogScope`) — zero third-party state
management packages. Pages read with `WalletStateScope.of(context)` to
subscribe to rebuilds, or `WalletStateScope.read(context)` for one-shot
reads inside async handlers.
