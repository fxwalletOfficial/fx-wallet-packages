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
import { MobileAdapter } from './MobileAdapter';

export class SolanaProvider extends BaseProvider implements ISolanaProvider {
  static NETWORK = 'solana';

  private mobileAdapter!: MobileAdapter;

  #disableMobileAdapter: boolean = false;

  #enableAdapter = true;

  connection!: Connection;

  publicKey!: PublicKey | null;

  isConnected: boolean = false;

  isFxWallet: boolean = true;

  #useLegacySign = false;

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

      if (typeof config.disableMobileAdapter !== 'undefined') {
        this.#disableMobileAdapter = config.disableMobileAdapter;
      }

      if (typeof config.useLegacySign !== 'undefined') {
        this.#useLegacySign = config.useLegacySign;
      }

      if (typeof config.isFxWallet !== 'undefined') {
        this.isFxWallet = config.isFxWallet;
      }
    }

    if (this.#enableAdapter) {
      initialize(this);
    }

    if (!this.#disableMobileAdapter) {
      this.mobileAdapter = new MobileAdapter(this, this.#useLegacySign);
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
   */
  async signTransaction<T extends Transaction | VersionedTransaction>(
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

  async signRawTransactionMulti<T extends Transaction | VersionedTransaction>(
    transactions: T[],
  ) {
    const signaturesEncoded = await this.#privateRequest<string[]>({
      method: 'signRawTransactionMulti',
      params: {
        transactions: transactions.map((tx) => {
          const data = JSON.stringify(tx);

          let version: string | number = 'legacy';
          let rawMessage: string;

          if (isVersionedTransaction(tx)) {
            version = tx.version;
            rawMessage = Buffer.from(tx.message.serialize()).toString('base64');
          } else {
            rawMessage = Buffer.from(tx.serializeMessage()).toString('base64');
          }

          const raw = Buffer.from(
            tx.serialize({
              requireAllSignatures: false,
              verifySignatures: false,
            }),
          ).toString('base64');

          return { data, raw, rawMessage, version };
        }),
      },
    });

    return signaturesEncoded.map((signature, i) =>
      this.mapSignedTransaction(transactions[i], signature),
    );
  }

  async signMessage(
    message: Uint8Array,
  ): Promise<{ signature: Uint8Array; publicKey: string | undefined }> {
    const hex = SolanaProvider.bufferToHex(message);

    const res = await callFlutterHandler<string>({
      method: 'solana_signMessage',
      params: { raw: hex },
    });

    return {
      signature: new Uint8Array(
        Buffer.from(SolanaProvider.messageToBuffer(res).buffer),
      ),
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

  #privateRequest<T>(args: IRequestArguments): Promise<T> {
    const next = () => {
      return this.internalRequest(args) as Promise<T>;
    };

    if (this.mobileAdapter) {
      return this.mobileAdapter.request(args, next);
    }

    return next();
  }

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
