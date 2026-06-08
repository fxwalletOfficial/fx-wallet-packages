/**
 * Aggregator entry for the WebView-injected provider bundle.
 *
 * `flutter_web3_webview` injects the resulting `provider.min.js` into every
 * page before any DApp script runs, then the Dart side (see
 * `lib/src/utils/provider.dart`) calls `new fxwallet.Provider(config)` and
 * `new fxwallet.SolanaProvider(config)` to construct the per-page providers.
 *
 * The shape of `window.fxwallet` therefore needs to exactly match the
 * previously-shipped bundle:
 *
 *   window.fxwallet = {
 *     Provider:        // EthereumProvider class
 *     SolanaProvider:  // SolanaProvider class
 *     postMessage:     // null placeholder kept for backwards compat
 *   };
 *
 * `SolanaProvider`'s constructor registers itself with the Solana wallet
 * standard internally (see `solana/SolanaProvider.ts:88` → `initialize(this)`
 * → `registerWallet(...)`), so the aggregator only needs to expose the
 * constructors.
 */

// Import directly from the workspace source. The aggregator is not published
// as an npm package, so going through the `@fxwallet/web3-provider-*`
// workspace names would only force a per-package symlink with no benefit;
// the relative paths let esbuild bundle the TypeScript directly.
import { EthereumProvider } from '../packages/ethereum';
import { SolanaProvider } from '../packages/solana';

type PostMessage = ((data: unknown) => void) | null;

type FxWalletGlobal = {
  Provider: typeof EthereumProvider;
  SolanaProvider: typeof SolanaProvider;
  postMessage: PostMessage;
};

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  interface Window {
    fxwallet?: FxWalletGlobal;
  }
}

const fxwallet: FxWalletGlobal = {
  Provider: EthereumProvider,
  SolanaProvider: SolanaProvider,
  postMessage: null,
};

(window as Window).fxwallet = fxwallet;
