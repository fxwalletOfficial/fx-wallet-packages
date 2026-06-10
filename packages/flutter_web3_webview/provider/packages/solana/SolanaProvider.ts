import 'rpc-websockets/dist/lib/client';

import {
  BaseProvider,
  IRequestArguments,
  callFlutterHandler,
} from '@fxwallet/web3-provider-core';
import type ISolanaProvider from './types/SolanaProvider';
import type { ISolanaProviderConfig } from './types/SolanaProvider';
import {
  SolanaSignInInput,
  SolanaSignInOutput,
} from '@solana/wallet-standard-features';
import {
  PublicKey,
  Transaction,
  VersionedTransaction,
  SendOptions,
  Connection,
} from '@solana/web3.js';
import initialize from './adapter/initialize';
import { FxWallet } from './adapter/wallet';
import { isVersionedTransaction } from './adapter/solana';
import * as bs58 from 'bs58';
// `MobileAdapter` is still vendored in `./MobileAdapter.ts` for reference
// but is not on the request hot path — `connect` / `signMessage` /
// `signTransaction` go straight through `callFlutterHandler`, so importing
// the adapter here would only force esbuild to keep its
// `method:"requestAccounts"` / similar dead-code case literals in the
// final bundle.

export class SolanaProvider extends BaseProvider implements ISolanaProvider {
  static NETWORK = 'solana';

  #enableAdapter = true;

  connection!: Connection;

  publicKey!: PublicKey | null;

  isConnected: boolean = false;

  isFxWallet: boolean = true;

  // Serialises `signTransaction` so concurrent calls from a DApp run one at
  // a time — the wallet can only present one approval UI per signature, so
  // racing requests would otherwise stomp on each other. Each call chains
  // onto the tail of this promise; the tail is kept rejection-free so one
  // failed signature doesn't block the rest of the queue. (Previously a
  // host-app userscript monkey-patched this onto the provider at runtime;
  // baking it into the provider removes the timing / re-entrancy guesswork.)
  #signTransactionQueue: Promise<unknown> = Promise.resolve();

  static bufferToHex(buffer: Buffer | Uint8Array | string) {
    return '0x' + Buffer.from(buffer).toString('hex');
  }

  static messageToBuffer(message: string | Buffer) {
    let buffer = Buffer.from([]);
    try {
      if (typeof message === 'string') {
        buffer = Buffer.from(message.replace('0x', ''), 'hex');
      } else {
        buffer = Buffer.from(message);
      }
    } catch (err) {
      console.log(`messageToBuffer error: ${err}`);
    }

    return buffer;
  }

  constructor(config?: ISolanaProviderConfig) {
    super();

    if (config) {
      if (typeof config.enableAdapter !== 'undefined') {
        this.#enableAdapter = config.enableAdapter;
      }

      if (typeof config.cluster !== 'undefined') {
        this.connection = new Connection(config.cluster, 'confirmed');
      }

      if (typeof config.isFxWallet !== 'undefined') {
        this.isFxWallet = config.isFxWallet;
      }
    }

    if (this.#enableAdapter) {
      initialize(this);
    }
  }

  getInstanceWithAdapter(): FxWallet {
    return new FxWallet(this);
  }

  /**
   * Resolve the active wallet account via the Flutter bridge.
   *
   * The Dart `Web3RequestDispatcher` handles the `solana_account` method
   * by returning the base58 public-key string of the currently selected
   * wallet (see `lib/src/utils/request_dispatcher.dart`). We wrap it back
   * into a `PublicKey`, flag `isConnected`, and emit the EIP-1193-style
   * `connect` event so the wallet-standard adapter and listening DApps
   * pick up the state change.
   */
  async connect(
    _options?: { onlyIfTrusted?: boolean | undefined } | undefined,
  ): Promise<{ publicKey: PublicKey }> {
    const address = await callFlutterHandler<string>({
      method: 'solana_account',
    });

    this.publicKey = new PublicKey(address);
    this.isConnected = true;
    this.emit('connect');

    return { publicKey: this.publicKey };
  }

  disconnect(): Promise<void> {
    return new Promise((resolve) => {
      this.publicKey = null;
      this.isConnected = false;
      this.emit('disconnect');
      resolve();
    });
  }

  /**
   * Notify listeners that the active Solana account changed. The Flutter
   * side calls this from `provider.dart` after the user switches wallets
   * so DApps subscribed via the wallet standard refresh their state.
   */
  emitAccountChanged(): void {
    this.emit('accountChanged', this.publicKey);
  }

  async signAndSendTransaction<T extends Transaction | VersionedTransaction>(
    transaction: T,
    options?: SendOptions | undefined,
  ): Promise<{ signature: string }> {
    const signedTx = await this.signTransaction(transaction);

    const signature = await this.connection.sendRawTransaction(
      signedTx.serialize(),
      options,
    );

    return { signature: signature };
  }

  /**
   * Serialise the transaction's *message* (the signed-over bytes, not the
   * full transaction) and ask the Flutter side to sign it. The wallet
   * receives both a hex (`raw`) and base64 (`message`) encoding of the
   * same bytes so it can pick whichever its native signer expects, and
   * replies with the base58-encoded signature, which `mapSignedTransaction`
   * attaches back to the original transaction object.
   *
   * Calls are serialised through `#signTransactionQueue` so a DApp issuing
   * several `signTransaction` requests at once (directly or via
   * `signAllTransactions`) gets them approved one at a time instead of
   * racing the single approval UI.
   */
  signTransaction<T extends Transaction | VersionedTransaction>(
    tx: T,
  ): Promise<T> {
    const run = (): Promise<T> => this.#doSignTransaction(tx);

    // `.then(run, run)` runs the next signature regardless of whether the
    // previous one resolved or rejected; the queued result is returned to
    // the caller, while the tail stored back on the queue is stripped of
    // its rejection so a failed signature can't wedge the whole queue.
    const result = this.#signTransactionQueue.then(run, run);
    this.#signTransactionQueue = result.catch(() => {});
    return result;
  }

  async #doSignTransaction<T extends Transaction | VersionedTransaction>(
    tx: T,
  ): Promise<T> {
    const message = isVersionedTransaction(tx)
      ? Buffer.from(tx.message.serialize())
      : tx.serializeMessage();

    const signature = await callFlutterHandler<string>({
      method: 'solana_signTransaction',
      params: {
        raw: message.toString('hex'),
        message: message.toString('base64'),
      },
    });

    return this.mapSignedTransaction(tx, signature);
  }

  signAllTransactions<T extends Transaction | VersionedTransaction>(
    transactions: T[],
  ): Promise<T[]> {
    return Promise.all(transactions.map((tx) => this.signTransaction(tx)));
  }

  // `signRawTransactionMulti` was present upstream but the legacy
  // `provider.min.js` did not ship it and the Dart `Web3RequestDispatcher`
  // has no matching case, so calls would silently fall through to
  // `_defaultCallback`. Removed here to keep the typed API honest; DApps
  // that need batch signing should call `signAllTransactions` (composed
  // from `signTransaction`) instead, which is what the upstream and the
  // legacy fork both wired up.

  async signMessage(
    message: Uint8Array,
  ): Promise<{ signature: Uint8Array; publicKey: string | undefined }> {
    const hex = SolanaProvider.bufferToHex(message);

    const res = await callFlutterHandler<string>({
      method: 'solana_signMessage',
      params: { raw: hex },
    });

    // Wrap the Buffer view itself (copying its valid bytes), NOT its
    // `.buffer`: the backing ArrayBuffer may be a larger pooled slab, so
    // `new Uint8Array(view.buffer)` can balloon a 64-byte signature past its
    // expected length (e.g. to the 8 KB pool size under Node's Buffer).
    const signature = SolanaProvider.messageToBuffer(res);
    return {
      signature: new Uint8Array(signature),
      publicKey: this.publicKey?.toBase58(),
    };
  }

  signIn(input?: SolanaSignInInput | undefined): Promise<SolanaSignInOutput> {
    throw new Error('Method not implemented.');
  }

  getNetwork(): string {
    return SolanaProvider.NETWORK;
  }

  mapSignedTransaction<T extends Transaction | VersionedTransaction>(
    transaction: T,
    signatureEncoded: string,
  ) {
    transaction.addSignature(
      this.publicKey!,
      bs58.decode(signatureEncoded) as Buffer & Uint8Array,
    );
    return transaction;
  }

  /**
   * `SolanaProvider` exposes its bridged methods directly (`connect`,
   * `signMessage`, `signTransaction`, …) — the generic `request` /
   * `internalRequest` are reserved for any future un-bridged method and
   * deliberately throw, mirroring the upstream which never finalised a
   * Solana `request` contract.
   */
  request<T>(_args: IRequestArguments): Promise<T> {
    throw new Error('Not implemented');
  }

  /**
   * Generic Solana bridge for callers that aren't covered by the bespoke
   * `connect` / `signMessage` / `signTransaction` overrides above. The
   * Dart side dispatches on the un-prefixed method name when it falls
   * through to `onDefaultCallback`, so we keep `args` intact rather than
   * synthesising a `solana_` prefix here.
   */
  internalRequest<T>(args: IRequestArguments): Promise<T> {
    return callFlutterHandler<T>(args);
  }
}
