import { test, expect, afterEach } from 'bun:test';

import { callFlutterHandler, ProviderRpcError } from '../adapter/FlutterBridge';

// Install a mock `window.flutter_inappwebview.callHandler` so `getBridge()`
// resolves; each test supplies the behaviour it needs.
function setBridge(
  callHandler: (handler: string, payload: unknown) => Promise<unknown>,
) {
  (globalThis as unknown as { window: unknown }).window = {
    flutter_inappwebview: { callHandler },
  };
}

afterEach(() => {
  delete (globalThis as unknown as { window?: unknown }).window;
});

test('resolves with the Dart-side result', async () => {
  setBridge(() => Promise.resolve('0xabc'));
  expect(await callFlutterHandler<string>({ method: 'eth_chainId' })).toBe(
    '0xabc',
  );
});

test('converts a Web3RpcError sentinel rejection into a ProviderRpcError', async () => {
  setBridge(() =>
    Promise.reject(
      new Error(
        'Error: x, Exception: Web3RpcError: {"code":4902,"message":"Unrecognized chain ID"}',
      ),
    ),
  );

  const error = await callFlutterHandler({
    method: 'wallet_switchEthereumChain',
  }).then(
    () => null,
    (e) => e,
  );

  expect(error).toBeInstanceOf(ProviderRpcError);
  expect((error as ProviderRpcError).code).toBe(4902);
  expect((error as ProviderRpcError).message).toBe('Unrecognized chain ID');
});

test('parses the sentinel even with trailing characters after the JSON', async () => {
  setBridge(() =>
    Promise.reject(
      'Web3RpcError: {"code":4001,"message":"User rejected the request"}\n  at <anonymous>',
    ),
  );

  const error = await callFlutterHandler({ method: 'personal_sign' }).then(
    () => null,
    (e) => e,
  );

  expect(error).toBeInstanceOf(ProviderRpcError);
  expect((error as ProviderRpcError).code).toBe(4001);
});

test('passes a non-sentinel rejection through unchanged', async () => {
  const original = new Error('Not init finished.');
  setBridge(() => Promise.reject(original));

  const error = await callFlutterHandler({ method: 'eth_accounts' }).then(
    () => null,
    (e) => e,
  );

  expect(error).toBe(original);
});
