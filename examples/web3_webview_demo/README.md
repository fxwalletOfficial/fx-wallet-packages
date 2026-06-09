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
| **3** | Full callback wiring + approval sheet + bridge log + wallet→DApp event emit (mock signers) | ✅ |
| **4** | Real EVM signing (`web3dart` + self-rolled EIP-712): `personal_sign`, `eth_sign`, `eth_signTypedData_v4`, `eth_sendTransaction` | ✅ this commit |
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

Signers are injected through `DemoApp` behind the `EthSigner` /
`SolSigner` interfaces. The EVM side now uses the **real** `web3dart`
implementation (`Web3DartEthSigner`); the Solana side is still
`MockSolSigner` until Phase 5. `MockEthSigner` is retained for tests.

## EVM signing (Phase 4)

`Web3DartEthSigner` produces cryptographically valid secp256k1 signatures
against the demo account's (public Hardhat) private key:

| Method | Implementation |
|--------|----------------|
| `personal_sign` | web3dart `signPersonalMessageToUint8List` (EIP-191) |
| `eth_sign` | raw `sign` over the 32-byte hash |
| `eth_signTypedData_v4` | `Eip712.digest` (self-rolled v4 encoder — supports nested structs + arrays) → `sign` |
| `eth_sendTransaction` | mock: signs the payload and returns a deterministic 32-byte hash; real-broadcast: builds an EIP-1559 tx and submits via `Web3Client` over the chain's RPC |

The EIP-712 encoder lives in `services/eip712.dart` and is validated in
tests against the canonical spec Mail/Person example
(digest `0xbe609a…57bd2`); signing tests recover the signer address from
the signature via `ecRecover` to prove correctness end-to-end.

> `web3dart 3.0.2` pins `pointycastle ^4`, which conflicts with
> `eth_sig_util` / `bip39` (both on `^3`). The demo therefore rolls its
> own EIP-712 encoder and hard-codes the public Hardhat private keys
> instead of deriving them at runtime.

State propagates through `InheritedNotifier`-backed scopes
(`WalletStateScope`, `BridgeLogScope`) — zero third-party state
management packages. Pages read with `WalletStateScope.of(context)` to
subscribe to rebuilds, or `WalletStateScope.read(context)` for one-shot
reads inside async handlers.
