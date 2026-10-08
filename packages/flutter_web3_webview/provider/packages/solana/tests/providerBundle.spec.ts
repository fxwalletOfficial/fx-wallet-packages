import { test, expect } from 'bun:test';
import { readFileSync } from 'node:fs';
import { createContext, runInContext } from 'node:vm';
import type { Wallet } from '@wallet-standard/base';

const providerJs = readFileSync(new URL('../../../../lib/js/provider.min.js', import.meta.url), 'utf8');

function registerBundledWallet(config?: { solana: Pick<Wallet, 'name' | 'icon'> }): Wallet {
  const wallets: Wallet[] = [];
  const window = {
    addEventListener() {},
    dispatchEvent(event: { type: string; detail: (api: { register: (wallet: Wallet) => void }) => void }) {
      if (event.type === 'wallet-standard:register-wallet') {
        event.detail({ register: (wallet) => wallets.push(wallet) });
      }
      return true;
    },
  };
  const context = createContext({
    window,
    config,
    console,
    Event,
    TextEncoder,
    TextDecoder,
    URL,
    URLSearchParams,
    setTimeout,
    clearTimeout,
    setInterval,
    clearInterval,
  });

  runInContext(providerJs, context);
  runInContext('new window.fxwallet.SolanaProvider(config)', context);

  expect(wallets).toHaveLength(1);
  return wallets[0]!;
}

test('bundled provider registers the configured Solana wallet name and icon', () => {
  const name = 'Custom Wallet';
  const icon = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciLz4=';
  const wallet = registerBundledWallet({ solana: { name, icon } });

  expect(wallet.name).toBe(name);
  expect(wallet.icon).toBe(icon);
});

test('bundled provider defaults to the Dart built-in wallet icon', () => {
  const params = readFileSync(new URL('../../../../lib/src/config/params.dart', import.meta.url), 'utf8');
  const defaultIcon = params.match(/WALLET_ICON\s*=\s*'([^']+)'/)![1];
  const wallet = registerBundledWallet();

  expect(wallet.name).toBe('FxWallet');
  expect<string>(wallet.icon).toBe(defaultIcon);
});
