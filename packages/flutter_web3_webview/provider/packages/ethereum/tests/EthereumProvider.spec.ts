import { test, expect, beforeEach, afterEach } from 'bun:test';

import { EthereumProvider } from '../EthereumProvider';
import { RPCError } from '../exceptions/RPCError';

const account = '0x0000000000000000000000000000000000000000';

// The current provider is a thin pass-through: `request` / `internalRequest`
// hand the DApp's `{ method, params }` straight to the Flutter bridge via
// `window.flutter_inappwebview.callHandler`. These tests capture what reaches
// the bridge (no MobileAdapter rewrite) and cover the synchronous / event
// helpers. (The old upstream `Web3Provider` + `AdapterStrategy` + handler
// tests were removed: that adapter is no longer on the request hot path.)
let calls: Array<{ method: string; params?: unknown }>;
let respond: (payload: { method: string; params?: unknown }) => Promise<unknown>;

function setBridge() {
  calls = [];
  respond = () => Promise.resolve(null);
  (globalThis as unknown as { window: unknown }).window = {
    flutter_inappwebview: {
      callHandler: (
        _handler: string,
        payload: { method: string; params?: unknown },
      ) => {
        calls.push(payload);
        return respond(payload);
      },
    },
  };
}

beforeEach(setBridge);
afterEach(() => {
  delete (globalThis as unknown as { window?: unknown }).window;
});

test('request forwards the EIP-1193 payload to the bridge unchanged', async () => {
  respond = () => Promise.resolve([account]);
  const ethereum = new EthereumProvider();

  expect(await ethereum.request({ method: 'eth_requestAccounts' })).toEqual([
    account,
  ]);
  expect(calls).toEqual([{ method: 'eth_requestAccounts' }]);
});

test('request keeps the original method names (no MobileAdapter rewrite)', async () => {
  const ethereum = new EthereumProvider();

  await ethereum.request({
    method: 'eth_sendTransaction',
    params: [{ from: account, to: account, value: '0x1' }],
  });
  await ethereum.request({
    method: 'personal_sign',
    params: ['0xdead', account],
  });
  await ethereum.request({ method: 'wallet_switchEthereumChain' });

  expect(calls.map((c) => c.method)).toEqual([
    'eth_sendTransaction',
    'personal_sign',
    'wallet_switchEthereumChain',
  ]);
});

test('internalRequest is the same single-step pass-through as request', async () => {
  respond = () => Promise.resolve('0x1');
  const ethereum = new EthereumProvider();

  expect(await ethereum.internalRequest({ method: 'eth_chainId' })).toBe('0x1');
  expect(calls).toEqual([{ method: 'eth_chainId' }]);
});

test('enable() proxies to eth_requestAccounts', async () => {
  respond = () => Promise.resolve([account]);
  const ethereum = new EthereumProvider();

  expect(await ethereum.enable()).toEqual([account]);
  expect(calls).toEqual([{ method: 'eth_requestAccounts' }]);
});

test('isMetaMask reflects the overwriteMetamask config', () => {
  expect(new EthereumProvider().isMetaMask).toBe(false);
  expect(new EthereumProvider({ overwriteMetamask: true }).isMetaMask).toBe(
    true,
  );
});

test('connected getter is always true', () => {
  expect(new EthereumProvider().connected).toBe(true);
});

test('emitChainChanged updates the chain id and fires chainChanged + networkChanged', () => {
  const ethereum = new EthereumProvider();
  const chainChanged: string[] = [];
  const networkChanged: string[] = [];
  ethereum.on('chainChanged', (id: string) => chainChanged.push(id));
  ethereum.on('networkChanged', (id: string) => networkChanged.push(id));

  ethereum.emitChainChanged('0x89');

  expect(ethereum.getChainId()).toBe('0x89');
  expect(chainChanged).toEqual(['0x89']);
  expect(networkChanged).toEqual(['0x89']);
});

test('emitAccountsChanged fires accountsChanged', () => {
  const ethereum = new EthereumProvider();
  const seen: string[][] = [];
  ethereum.on('accountsChanged', (accounts: string[]) => seen.push(accounts));

  ethereum.emitAccountsChanged([account]);

  expect(seen).toEqual([[account]]);
});

test('_send answers eth_accounts synchronously from the cached address', () => {
  const ethereum = new EthereumProvider();
  expect(ethereum._send({ method: 'eth_accounts' }).result).toEqual([]);

  ethereum.setAddress(account);
  expect(ethereum._send({ method: 'eth_accounts' }).result).toEqual([account]);
});

test('request(eth_requestAccounts) caches the address for the sync _send path', async () => {
  respond = () => Promise.resolve([account]);
  const ethereum = new EthereumProvider();

  // Nothing cached before connecting.
  expect(ethereum._send({ method: 'eth_accounts' }).result).toEqual([]);

  await ethereum.request({ method: 'eth_requestAccounts' });

  // request() fires onResponseReady, which caches the address so the
  // synchronous eth_accounts / eth_coinbase path returns it.
  expect(ethereum._send({ method: 'eth_accounts' }).result).toEqual([account]);
  expect(ethereum._send({ method: 'eth_coinbase' }).result).toEqual([account]);
});

test('_send throws 4200 for synchronous net_version / eth_chainId', () => {
  const ethereum = new EthereumProvider({ chainId: '0x9' });
  expect(() => ethereum._send({ method: 'net_version' })).toThrow(RPCError);
  expect(() => ethereum._send({ method: 'eth_chainId' })).toThrow(RPCError);
});

test('getNetworkVersion parses the cached chain id (no stray space in the method name)', () => {
  expect(new EthereumProvider().getNetworkVersion()).toBeUndefined();
  expect(new EthereumProvider({ chainId: '0x9' }).getNetworkVersion()).toBe(9);
});
