import { test, expect, beforeEach } from 'bun:test';

import { SolanaProvider } from '../SolanaProvider';
import { window as walletWindow } from './mocks/window';
import { PublicKey, SystemProgram, Transaction } from '@solana/web3.js';

const account = '3z9vL1zjN6qyAFHhHQdWYRTFAcy69pJydkZmSFBKHg1R';
// 64-byte base58 signature (signTransaction reply, attached via addSignature).
const signature =
  '5LrcE2f6uvydKRquEJ8xp19heGxSvqsVbcqUeFoiWbXe8JNip7ftPQNTAVPyTK7ijVdpkzmKKaAQR7MWMmujAhXD';
// 64-byte hex signature (signMessage reply, decoded via messageToBuffer).
const messageSignatureHex = '0x' + '11'.repeat(64);

// The mock window doubles as the wallet-standard registration target (its
// dispatchEvent captures `window.wallet`) and the Flutter bridge host.
// (The old upstream `Web3Provider` + `AdapterStrategy` + handler tests were
// removed: the provider bridges straight through `callFlutterHandler` now.)
global.window = walletWindow;

let calls: Array<{ method: string; params?: any }>;

function setBridge() {
  calls = [];
  (walletWindow as any).flutter_inappwebview = {
    callHandler: (
      _handler: string,
      payload: { method: string; params?: any },
    ) => {
      calls.push(payload);
      switch (payload.method) {
        case 'solana_account':
          return Promise.resolve(account);
        case 'solana_signMessage':
          return Promise.resolve(messageSignatureHex);
        case 'solana_signTransaction':
          return Promise.resolve(signature);
        default:
          return Promise.resolve(null);
      }
    },
  };
}

function makeTransaction(): Transaction {
  const key = new PublicKey(account);
  const tx = new Transaction().add(
    SystemProgram.transfer({ fromPubkey: key, toPubkey: key, lamports: 100 }),
  );
  tx.feePayer = key;
  tx.recentBlockhash = '6VdVbpsv7b5cSekEimjMTddydrikUsbeXQcizEk6LqSn';
  return tx;
}

beforeEach(setBridge);

test('connect bridges to solana_account and sets the public key', async () => {
  const sol = new SolanaProvider({ enableAdapter: false });
  const { publicKey } = await sol.connect();

  expect(calls).toEqual([{ method: 'solana_account' }]);
  expect(publicKey.toBase58()).toBe(account);
  expect(sol.isConnected).toBe(true);
});

test('signMessage bridges the message as hex under solana_signMessage', async () => {
  const sol = new SolanaProvider({ enableAdapter: false });
  await sol.connect();

  const message = Buffer.from('Random message');
  const { signature } = await sol.signMessage(new Uint8Array(message));

  expect(calls[1]).toEqual({
    method: 'solana_signMessage',
    params: { raw: '0x' + message.toString('hex') },
  });
  // The reply is a 64-byte ed25519 signature — it must reflect the Buffer's
  // valid length, not the (possibly larger, pooled) backing ArrayBuffer.
  expect(signature).toBeInstanceOf(Uint8Array);
  expect(signature.length).toBe(64);
});

test('signTransaction bridges the message as hex + base64 under solana_signTransaction', async () => {
  const sol = new SolanaProvider({ enableAdapter: false });
  await sol.connect();

  const tx = makeTransaction();
  const message = tx.serializeMessage();
  await sol.signTransaction(tx);

  expect(calls[1]).toEqual({
    method: 'solana_signTransaction',
    params: {
      raw: message.toString('hex'),
      message: message.toString('base64'),
    },
  });
});

test('the wallet-standard adapter advertises only the supported features', () => {
  // Registering through `initialize` (the default) publishes the FxWallet to
  // the mock window. signAndSendTransaction / signIn must NOT be advertised —
  // the provider has no default broadcast RPC and SIWS isn't bridged.
  new SolanaProvider();
  const features = Object.keys(walletWindow.wallet.features);

  expect(features).toContain('standard:connect');
  expect(features).toContain('solana:signTransaction');
  expect(features).toContain('solana:signMessage');
  expect(features).not.toContain('solana:signAndSendTransaction');
  expect(features).not.toContain('solana:signIn');
});
