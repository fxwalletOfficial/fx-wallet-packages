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
| **4** | Real EVM signing (`web3dart` + self-rolled EIP-712): `personal_sign`, `eth_sign`, `eth_signTypedData_v4`, `eth_sendTransaction` | ✅ |
| **5** | Real Solana signing (`cryptography` ed25519 + self-rolled base58): `solana_signMessage`, `solana_signTransaction` | ✅ |
| **6** | Settings: auto-approve toggle, real-broadcast toggle (testnet warning), full-screen bridge-log viewer | ✅ |
| **7** | Screen-by-screen docs, manual regression checklist, picker tests | ✅ this commit |

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

Three fixed demo identities (`kDemoAccounts`):

* **EVM** keys are the first three accounts of the well-known
  `test test test test test test test test test test test junk`
  mnemonic — the default Hardhat / Anvil accounts. Their private keys are
  hard-coded (and marked public) so the demo signs real secp256k1
  signatures; runtime BIP-44 derivation is skipped because `web3dart`'s
  `pointycastle ^4` conflicts with every BIP-39 package's `^3`.
* **Solana** keys are fixed 32-byte ed25519 seeds (`solanaSeed`); the
  catalogue `solanaAddress` is `base58(ed25519PublicKey(seed))`, asserted
  in `test/sol_signing_test.dart`.

**These are throwaway public test keys.** Anything sent to these
addresses is swept instantly by bots that scan for the mnemonic. Never
fund them.

## Architecture

```
lib/
├── main.dart            # entrypoint — Web3Webview.initJs() + runApp
├── app.dart             # MaterialApp + named routes + service scopes
├── data/
│   ├── chains.dart      # EVM chains + Solana clusters catalogue
│   ├── dapps.dart       # bookmark catalogue grouped by category
│   └── url_utils.dart   # custom-URL normalisation + host labelling
├── services/
│   ├── wallet_state.dart    # ChangeNotifier — active account / chain / settings
│   ├── bridge_log.dart      # ring-buffer log of bridge round-trips
│   ├── recent_visits.dart   # in-memory MRU of opened DApps
│   ├── request_summary.dart # parses a request into approval-sheet rows
│   ├── eth_signer.dart      # EthSigner: Web3DartEthSigner (real) + Mock
│   ├── eip712.dart          # self-rolled EIP-712 v4 encoder
│   ├── sol_signer.dart      # SolSigner: Ed25519SolSigner (real) + Mock
│   └── base58.dart          # base58 + hex codecs (no bs58 dependency)
├── pages/
│   ├── home_page.dart    # URL bar + search + recent row + bookmark grid
│   ├── browser_page.dart # Web3Webview — full callback wiring + emits
│   ├── settings_page.dart # account / chain pickers + behaviour toggles
│   └── log_page.dart      # full-screen bridge-log viewer
└── widgets/
    ├── dapp_bookmark_grid.dart # reusable grid + tile + filter helper
    ├── approval_sheet.dart     # modal confirm sheet (approve / reject)
    └── debug_panel.dart        # BridgeLogList + browser-page bottom sheet
```

## Settings (Phase 6)

| Control | Effect |
|---------|--------|
| Auto-approve read-only methods | `eth_accounts` / `eth_chainId` / `solana_account` resolve without a sheet |
| Broadcast transactions over RPC | `eth_sendTransaction` signs + submits over RPC instead of returning a mock hash; warns when the active chain is not a testnet |
| Bridge call log | opens the full-screen viewer (live entry-count badge), shared rendering with the browser-page sheet via `BridgeLogList` |

## Bridge wiring (Phase 3)

`browser_page.dart` connects every `Web3Webview` callback:

| Callback | Behaviour |
|----------|-----------|
| `ethAccounts` / `ethChainId` / `solAccount` | resolve immediately when *auto-approve reads* is on, else prompt |
| `ethPersonalSign` / `ethSign` / `ethSignTypedData` | approval sheet → `EthSigner` |
| `ethSendTransaction` | approval sheet (danger styling) → `EthSigner`, mock hash unless *real broadcast* |
| `walletSwitchEthereumChain` | approval sheet → updates `WalletState` (returns `false` on reject so the dispatcher raises EIP-1193 `4001`) |
| `walletAddEthereumChain` | approval sheet → registers the chain **without** switching (EIP-3085); without this handler the dispatcher rejects add with `4200` |
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
`SolSigner` interfaces. Both sides now use **real** implementations
(`Web3DartEthSigner`, `Ed25519SolSigner`); the `Mock*` signers are
retained for tests.

## Solana signing (Phase 5)

`Ed25519SolSigner` signs with the `cryptography` package's ed25519 over
each account's fixed demo seed, plus a hand-rolled base58 codec
(`services/base58.dart`) — matching the "roll the Solana bits yourself"
choice. The two methods return **different encodings** on purpose,
matching what the injected provider JS expects:

| Method | Returns | Why |
|--------|---------|-----|
| `solana_signMessage` | hex (`0x…`) | provider decodes via `messageToBuffer` (hex) |
| `solana_signTransaction` | base58 | provider decodes via `bs58.decode` |

The Solana demo addresses are `base58(ed25519PublicKey(seed))`, verified
against the seeds in `test/sol_signing_test.dart` so the catalogue can
never drift from the keys.

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

## Screens

| Screen | What it does |
|--------|--------------|
| **Home** (`home_page.dart`) | Active-identity card; custom-URL bar (type a host or full URL); live bookmark search; recent-visit chip row; bookmark grid grouped by category. Tapping anything records a visit and opens the browser. |
| **Browser** (`browser_page.dart`) | `Web3Webview` hosting the DApp, with chain / account chips and a bridge-log (terminal) button in the AppBar. All EIP-1193 + Solana callbacks are wired here. Switching identity in Settings while a DApp stays open pushes `chainChanged` / `accountsChanged` / `accountChanged` events into the page. |
| **Settings** (`settings_page.dart`) | EVM + Solana account pickers, EVM chain + Solana cluster pickers, the auto-approve / real-broadcast toggles, and the bridge-log entry. |
| **Bridge log** (`log_page.dart`) | Full-screen, append-only timeline of every bridge round-trip with expandable request / response JSON; Clear in the AppBar. |
| **Approval sheet** (`approval_sheet.dart`) | Modal shown before every sign / send / chain-switch; Reject maps to an EIP-1193 `4001` the DApp sees. |

## Manual regression checklist

Use this to verify a provider-JS or dispatcher change end-to-end. Run
`flutter run`, then:

> **Two gotchas when testing on real EVM DApps:**
> 1. The demo sets `overwriteMetamask: true` (in `browser_page.dart`) so
>    `window.ethereum.isMetaMask` reports `true`. The official MetaMask
>    test dapp and many others gate signing / advanced features on this
>    flag; without it those buttons stay disabled. The package itself
>    defaults to `false` (`Web3EthSettings.overwriteMetamask`).
> 2. The demo's EVM accounts are the **public Hardhat keys**, which
>    mainstream DApps (OpenSea, …) block as known/abused addresses
>    ("account has been disabled"). For EVM signing flows prefer a DApp
>    that doesn't reputation-gate the address, or a testnet. The Solana
>    accounts have no such problem (Magic Eden SIWS login works
>    end-to-end).

**EVM (open the MetaMask test dapp from the Tools bookmarks)**

- [ ] **Connect** — the page shows the active account address; with
  *auto-approve reads* on (default) no sheet appears, with it off a
  Connect sheet does.
- [ ] **`eth_chainId` / `eth_accounts`** — the dapp reflects the active
  chain + account; both appear in the bridge log.
- [ ] **`personal_sign`** — the sheet shows the decoded message; approving
  returns a signature the dapp verifies; rejecting shows the dapp a
  user-rejected (`4001`) error.
- [ ] **`eth_signTypedData_v4`** — sheet shows domain + primary type;
  signature verifies on the dapp.
- [ ] **`eth_sendTransaction`** — sheet shows from / to / value / gas /
  data with a red Send button; mock mode returns a hash without
  broadcasting.
- [ ] **`wallet_switchEthereumChain`** — sheet shows from → to; approving
  updates the AppBar chain chip and the dapp's `chainChanged`.
- [ ] **`wallet_addEthereumChain`** — "Add chain" sheet; approving resolves
  the dapp call (null) without changing the active chain.
- [ ] **Wallet → DApp** — with the dapp open, change the active chain /
  account in Settings; the dapp receives the corresponding event (visible
  in the bridge log too).

**Solana (open Jupiter or Magic Eden)**

- [ ] **Connect** — wallet-standard detects the provider; `solana_account`
  resolves to the active Solana address.
- [ ] **`solana_signMessage`** — sheet shows the raw bytes; the dapp
  accepts the (hex-encoded) signature.
- [ ] **`solana_signTransaction`** — the dapp accepts the (base58-encoded)
  signature and can submit the transaction.

**Diagnostics**

- [ ] Every step above appears in the bridge log with timing; expanding an
  entry shows the request + response JSON.
- [ ] Toggling *real broadcast* on a non-testnet chain shows the warning.
