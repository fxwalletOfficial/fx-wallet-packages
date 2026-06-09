# flutter_web3_webview

A Flutter WebView widget that lets in-app web pages talk to a Web3 wallet. It
injects a provider bridge into every page so DApps can connect and request
signatures over **EIP-1193** (EVM) and the **Solana wallet standard**, while
your Dart code stays in control of accounts, chains, and every signing
prompt. Built on top of
[`flutter_inappwebview`](https://pub.dev/packages/flutter_inappwebview).

## Features

- Injects `window.ethereum` (EIP-1193 + EIP-6963) and a Solana
  wallet-standard provider (`window.fxwallet`) before page scripts run.
- Routes every wallet request to your Dart callbacks — you decide what to
  approve, sign, and return.
- EVM: `eth_requestAccounts`, `eth_accounts`, `eth_chainId`, `personal_sign`,
  `eth_sign`, `eth_signTypedData` (`v3` / `v4`), `eth_sendTransaction`,
  `wallet_switchEthereumChain` / `wallet_addEthereumChain`.
- Solana: connect (`solana_account`), `solana_signMessage`,
  `solana_signTransaction` (serialised so concurrent requests are approved
  one at a time).
- Push wallet-side changes back into the page: chain and account switches
  emit `chainChanged` / `accountsChanged` to listening DApps.
- Optional MetaMask impersonation (`window.ethereum.isMetaMask`) for DApps
  that gate on it — off by default.
- A drop-in superset of `InAppWebView`: every `flutter_inappwebview`
  callback is forwarded through.

## Installation

```yaml
dependencies:
  flutter_web3_webview: ^1.0.0
```

## Usage

Load the injected provider asset once (e.g. in `main`), then drop a
`Web3Webview` into your widget tree and wire the wallet callbacks:

```dart
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Web3Webview.initJs(); // load the provider bundle once
  runApp(const MyApp());
}

Web3Webview(
  initialUrlRequest: URLRequest(url: WebUri('https://app.uniswap.org')),
  settings: Web3Settings(
    name: 'My Wallet',
    eth: Web3EthSettings(
      chainId: 1,
      // Report window.ethereum.isMetaMask === true for DApps that require it.
      overwriteMetamask: false,
    ),
  ),

  // EVM ------------------------------------------------------------------
  ethAccounts: () async => ['0xYourAddress'],
  ethChainId: () async => 1,
  ethPersonalSign: (message) async => wallet.personalSign(message),
  ethSignTypedData: (json) async => wallet.signTypedDataV4(json),
  ethSendTransaction: (tx) async => wallet.sendTransaction(tx),
  walletSwitchEthereumChain: (chain) async {
    // Return true to accept the switch, false to reject (DApp sees 4001).
    return askUserToSwitch(chain);
  },

  // Solana ---------------------------------------------------------------
  solAccount: () async => 'YourBase58SolanaAddress',
  solSignMessage: (data) async => wallet.solSignMessage(data),
  solSignTransaction: (data) async => wallet.solSignTransaction(data),
)
```

Returning a value resolves the DApp's request; throwing rejects it. To
surface a real wallet rejection, throw an error whose `toString()` carries
the EIP-1193 `4001` shape.

## Wallet callbacks

| Callback | Triggered by | Returns |
|----------|--------------|---------|
| `ethAccounts` | `eth_requestAccounts` / `eth_accounts` | `List<String>` of addresses |
| `ethChainId` | `eth_chainId` | chain id as `int` |
| `ethPersonalSign` | `personal_sign` | signature hex |
| `ethSign` | `eth_sign` | signature hex |
| `ethSignTypedData` | `eth_signTypedData` / `_v3` / `_v4` | signature hex |
| `ethSendTransaction` | `eth_sendTransaction` | transaction hash |
| `walletSwitchEthereumChain` | `wallet_switchEthereumChain` / `wallet_addEthereumChain` | `bool` accept / reject |
| `solAccount` | Solana connect | base58 address |
| `solSignMessage` | `solana_signMessage` | signature (hex) |
| `solSignTransaction` | `solana_signTransaction` | signature (base58) |
| `onDefaultCallback` | any other method | anything (or throw) |

## Example

A full end-to-end demo — exercising every callback against real DApps, with
real signing — lives at
[`examples/web3_webview_demo`](https://github.com/fxwalletOfficial/fx-wallet-packages/tree/main/examples/web3_webview_demo).

## License

MIT — see [LICENSE](LICENSE).
