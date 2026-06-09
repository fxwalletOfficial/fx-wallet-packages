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

// Import the two providers through their workspace package entry points.
// Each sub-package's package.json resolves to its rollup `dist/` build, so
// esbuild bundles the compiled `dist/` output here (NOT the .ts sources) —
// run `build:packages` before `build:flutter` so these reflect the latest
// source. The aggregator isn't published as an npm package; the relative
// paths just avoid a per-package symlink.
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
