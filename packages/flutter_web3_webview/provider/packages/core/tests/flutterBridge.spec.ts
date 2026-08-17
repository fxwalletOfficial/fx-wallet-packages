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

test('stamps every outgoing payload with a request id', async () => {
  const payloads: Array<Record<string, unknown>> = [];
  setBridge((_handler, payload) => {
    payloads.push(payload as Record<string, unknown>);
    return Promise.resolve(null);
  });

  await callFlutterHandler({ method: 'personal_sign', params: ['0x1'] });
  await callFlutterHandler({ method: 'eth_sendTransaction' });

  // The id is what lets the Dart queue name the request (cancel it, line the
  // two sides' logs up), so it must be present and unique per call.
  expect(typeof payloads[0].id).toBe('string');
  expect(payloads[0].id).not.toBe(payloads[1].id);
  // method / params still travel verbatim: older Dart hosts read only those
  // and ignore the extra key.
  expect(payloads[0].method).toBe('personal_sign');
  expect(payloads[0].params).toEqual(['0x1']);
});

test('ids share a per-instance prefix and increment monotonically', async () => {
  const ids: string[] = [];
  setBridge((_handler, payload) => {
    ids.push((payload as { id: string }).id);
    return Promise.resolve(null);
  });

  await callFlutterHandler({ method: 'eth_chainId' });
  await callFlutterHandler({ method: 'eth_chainId' });

  const [first, second] = ids.map((id) => id.split('-'));
  // The random prefix keeps ids from colliding across frames, which each get
  // their own bundle instance but share one Dart handler.
  expect(first[0]).toBe(second[0]);
  expect(first[0]).toMatch(/^fxw[a-z0-9]+$/);
  expect(Number(second[1])).toBe(Number(first[1]) + 1);
});

test('keeps an id the caller supplied instead of minting a new one', async () => {
  let seen: unknown;
  setBridge((_handler, payload) => {
    seen = (payload as { id: unknown }).id;
    return Promise.resolve(null);
  });

  await callFlutterHandler({ method: 'eth_chainId', id: 'caller-owned' });

  expect(seen).toBe('caller-owned');
});
