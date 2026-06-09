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
| **1** | App shell + zero-dep state mgmt + bookmark grid + chain / account pickers (placeholders for signing / approval / log) | ✅ |
| **2** | Custom-URL bar, live bookmark search, in-memory recent-visit row | ✅ |
| **3** | Full callback wiring + approval sheet + bridge log + wallet→DApp event emit (mock signers) | ✅ this commit |
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
├── data/
│   └── url_utils.dart   # custom-URL normalisation + host labelling
├── services/
│   ├── wallet_state.dart    # ChangeNotifier — active account / chain / settings
│   ├── bridge_log.dart      # ring-buffer log of bridge round-trips
│   ├── recent_visits.dart   # in-memory MRU of opened DApps
│   ├── request_summary.dart # parses a request into approval-sheet rows
│   ├── eth_signer.dart      # EthSigner interface + MockEthSigner
│   └── sol_signer.dart      # SolSigner interface + MockSolSigner
├── pages/
│   ├── home_page.dart    # URL bar + search + recent row + bookmark grid
│   ├── browser_page.dart # Web3Webview — full callback wiring + emits
│   └── settings_page.dart # account / chain picker + (pending) toggles
└── widgets/
    ├── dapp_bookmark_grid.dart # reusable grid + tile + filter helper
    ├── approval_sheet.dart     # modal confirm sheet (approve / reject)
    └── debug_panel.dart        # bridge-log bottom sheet
```

## Bridge wiring (Phase 3)

`browser_page.dart` connects every `Web3Webview` callback:

| Callback | Behaviour |
|----------|-----------|
| `ethAccounts` / `ethChainId` / `solAccount` | resolve immediately when *auto-approve reads* is on, else prompt |
| `ethPersonalSign` / `ethSign` / `ethSignTypedData` | approval sheet → `EthSigner` |
| `ethSendTransaction` | approval sheet (danger styling) → `EthSigner`, mock hash unless *real broadcast* |
| `walletSwitchEthereumChain` | approval sheet → updates `WalletState` (returns `false` on reject so the dispatcher raises EIP-1193 `4001`) |
| `solSignMessage` / `solSignTransaction` | approval sheet → `SolSigner` |
| `onDefaultCallback` | logged + rejected so unknown methods fail loudly |

Rejecting any sheet throws `UserRejectedException` whose `toString()` is the
EIP-1193 `4001` JSON, so the DApp sees a real wallet's rejection shape.

The page also shows the **wallet → DApp** direction: while a DApp is open,
switching the active chain / EVM account / Solana account (e.g. from
Settings) pushes `emitChainChanged` / `emitAccountsChanged` /
`solana.emitAccountChanged` into the page via `evaluateJavascript`.

Every round-trip — including the emits — is recorded in the `BridgeLog`,
viewable from the browser AppBar's terminal icon.

Signers are **mock** in this phase: deterministic placeholder signatures
that exercise the plumbing but are not cryptographically valid. Phase 4 / 5
swap in the real `web3dart` / ed25519 implementations behind the same
`EthSigner` / `SolSigner` interfaces (injected through `DemoApp`).

State propagates through `InheritedNotifier`-backed scopes
(`WalletStateScope`, `BridgeLogScope`) — zero third-party state
management packages. Pages read with `WalletStateScope.of(context)` to
subscribe to rebuilds, or `WalletStateScope.read(context)` for one-shot
reads inside async handlers.
