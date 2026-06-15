import { test, expect, beforeEach } from 'bun:test';
import {
  PublicKey,
  SystemProgram,
  Transaction,
} from '@solana/web3.js';

import { SolanaProvider } from '../SolanaProvider';

// A valid base58, 64-byte signature the provider can attach via
// `mapSignedTransaction` (account below is both fee payer and signer).
const account = '3z9vL1zjN6qyAFHhHQdWYRTFAcy69pJydkZmSFBKHg1R';
const signature =
  '5LrcE2f6uvydKRquEJ8xp19heGxSvqsVbcqUeFoiWbXe8JNip7ftPQNTAVPyTK7ijVdpkzmKKaAQR7MWMmujAhXD';

function makeTransaction(): Transaction {
  const key = new PublicKey(account);
  const tx = new Transaction().add(
    SystemProgram.transfer({
      fromPubkey: key,
      toPubkey: key,
      lamports: 100,
    }),
  );
  tx.feePayer = key;
  tx.recentBlockhash = '6VdVbpsv7b5cSekEimjMTddydrikUsbeXQcizEk6LqSn';
  return tx;
}

const tick = () => new Promise((r) => setTimeout(r, 0));

// Hooks into the in-flight signTransaction calls so the test can hold them
// open and observe ordering.
let activeSigns = 0;
let maxActiveSigns = 0;
let signResolvers: Array<() => void>;

beforeEach(() => {
  activeSigns = 0;
  maxActiveSigns = 0;
  signResolvers = [];

  // Mock the Flutter WebView bridge. `solana_account` resolves immediately
  // (so `connect` can set the public key); `solana_signTransaction` parks
  // until the test releases it, recording concurrency along the way.
  (globalThis as unknown as { window: unknown }).window = {
    flutter_inappwebview: {
      callHandler: (_handler: string, payload: { method: string }) => {
        if (payload.method === 'solana_account') {
          return Promise.resolve(account);
        }
        if (payload.method === 'solana_signTransaction') {
          activeSigns += 1;
          maxActiveSigns = Math.max(maxActiveSigns, activeSigns);
          return new Promise<string>((resolve) => {
            signResolvers.push(() => {
              activeSigns -= 1;
              resolve(signature);
            });
          });
        }
        return Promise.resolve(null);
      },
    },
  };
});

test('signTransaction runs concurrent calls one at a time', async () => {
  const sol = new SolanaProvider({ enableAdapter: false });
  await sol.connect();

  // Fire three signTransaction calls without awaiting — they should queue.
  const p1 = sol.signTransaction(makeTransaction());
  const p2 = sol.signTransaction(makeTransaction());
  const p3 = sol.signTransaction(makeTransaction());

  await tick();
  // Only the first request has reached the bridge.
  expect(maxActiveSigns).toBe(1);
  expect(signResolvers.length).toBe(1);

  // Releasing #1 lets #2 start, and so on — never two in flight at once.
  signResolvers[0]();
  await tick();
  expect(signResolvers.length).toBe(2);
  expect(activeSigns).toBe(1);

  signResolvers[1]();
  await tick();
  expect(signResolvers.length).toBe(3);
  expect(activeSigns).toBe(1);

  signResolvers[2]();
  await Promise.all([p1, p2, p3]);

  expect(maxActiveSigns).toBe(1);
});

test('a rejected signTransaction does not wedge the queue', async () => {
  const sol = new SolanaProvider({ enableAdapter: false });
  await sol.connect();

  // First call rejects; the second must still proceed.
  let rejectFirst: (e: Error) => void = () => {};
  (globalThis as unknown as { window: any }).window.flutter_inappwebview
    .callHandler = (_h: string, payload: { method: string }) => {
    if (payload.method === 'solana_account') return Promise.resolve(account);
    if (payload.method === 'solana_signTransaction') {
      activeSigns += 1;
      maxActiveSigns = Math.max(maxActiveSigns, activeSigns);
      return new Promise<string>((resolve, reject) => {
        if (signResolvers.length === 0) {
          rejectFirst = (e) => {
            activeSigns -= 1;
            reject(e);
          };
          signResolvers.push(() => {});
        } else {
          signResolvers.push(() => {
            activeSigns -= 1;
            resolve(signature);
          });
        }
      });
    }
    return Promise.resolve(null);
  };

  const p1 = sol.signTransaction(makeTransaction());
  const p2 = sol.signTransaction(makeTransaction());

  await tick();
  expect(activeSigns).toBe(1); // only #1 in flight

  rejectFirst(new Error('user rejected'));
  await tick();

  // #1 rejected, #2 started.
  await expect(p1).rejects.toThrow('user rejected');
  expect(signResolvers.length).toBe(2);
  expect(activeSigns).toBe(1);

  signResolvers[1]();
  await p2;
  expect(maxActiveSigns).toBe(1);
});
