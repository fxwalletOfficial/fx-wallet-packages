import {
  SolanaSignMessage,
  type SolanaSignMessageFeature,
  type SolanaSignMessageMethod,
  type SolanaSignMessageOutput,
  SolanaSignTransaction,
  type SolanaSignTransactionFeature,
  type SolanaSignTransactionMethod,
  type SolanaSignTransactionOutput,
} from '@solana/wallet-standard-features';
import { Transaction, VersionedTransaction } from '@solana/web3.js';
import type { Wallet } from '@wallet-standard/base';
import {
  StandardConnect,
  type StandardConnectFeature,
  type StandardConnectMethod,
  StandardDisconnect,
  type StandardDisconnectFeature,
  type StandardDisconnectMethod,
  StandardEvents,
  type StandardEventsFeature,
  type StandardEventsListeners,
  type StandardEventsNames,
  type StandardEventsOnMethod,
} from '@wallet-standard/features';
import { FxWalletAccount } from './account';
import { icon } from './icon';
import type { SolanaChain } from './solana';
import { isSolanaChain, isVersionedTransaction, SOLANA_CHAINS } from './solana';
import { bytesEqual } from '../util';
import ISolanaProvider from '../types/SolanaProvider';

export const FxNamespace = 'fxwallet:';

export type FxFeature = {
  [FxNamespace]: {
    fx: ISolanaProvider;
  };
};

export class FxWallet implements Wallet {
  readonly #listeners: {
    [E in StandardEventsNames]?: StandardEventsListeners[E][];
  } = {};
  readonly #version = '1.0.0' as const;
  readonly #name = 'FxWallet' as const;
  readonly #icon = icon;
  #account: FxWalletAccount | null = null;
  readonly #fx: ISolanaProvider;

  get version() {
    return this.#version;
  }

  get name() {
    return this.#name;
  }

  get icon() {
    return this.#icon;
  }

  get chains() {
    return SOLANA_CHAINS.slice();
  }

  get features(): StandardConnectFeature &
    StandardDisconnectFeature &
    StandardEventsFeature &
    SolanaSignTransactionFeature &
    SolanaSignMessageFeature &
    FxFeature {
    // `SolanaSignAndSendTransaction` and `SolanaSignIn` are intentionally
    // NOT advertised: the provider has no broadcast RPC wired up by default
    // (so signAndSendTransaction can't send) and SIWS isn't bridged, so a
    // DApp picking those features would hit a runtime failure. Omitting them
    // lets DApps fall back to `signTransaction` / `connect` + `signMessage`.
    return {
      [StandardConnect]: {
        version: '1.0.0',
        connect: this.#connect,
      },
      [StandardDisconnect]: {
        version: '1.0.0',
        disconnect: this.#disconnect,
      },
      [StandardEvents]: {
        version: '1.0.0',
        on: this.#on,
      },
      [SolanaSignTransaction]: {
        version: '1.0.0',
        supportedTransactionVersions: ['legacy', 0],
        signTransaction: this.#signTransaction,
      },
      [SolanaSignMessage]: {
        version: '1.0.0',
        signMessage: this.#signMessage,
      },
      [FxNamespace]: {
        fx: this.#fx,
      },
    };
  }

  get accounts() {
    return this.#account ? [this.#account] : [];
  }

  constructor(fx: ISolanaProvider) {
    if (new.target === FxWallet) {
      Object.freeze(this);
    }

    this.#fx = fx;

    fx.on('connect', this.#connected, this);
    fx.on('disconnect', this.#disconnected, this);
    fx.on('accountChanged', this.#reconnected, this);

    this.#connected();
  }

  #on: StandardEventsOnMethod = (event, listener) => {
    this.#listeners[event]?.push(listener) ||
      (this.#listeners[event] = [listener]);
    return (): void => this.#off(event, listener);
  };

  #emit<E extends StandardEventsNames>(
    event: E,
    ...args: Parameters<StandardEventsListeners[E]>
  ): void {
    // eslint-disable-next-line prefer-spread
    this.#listeners[event]?.forEach((listener) => listener.apply(null, args));
  }

  #off<E extends StandardEventsNames>(
    event: E,
    listener: StandardEventsListeners[E],
  ): void {
    this.#listeners[event] = this.#listeners[event]?.filter(
      (existingListener) => listener !== existingListener,
    );
  }

  #connected = () => {
    const address = this.#fx.publicKey?.toBase58();
    if (address) {
      const publicKey = this.#fx.publicKey!.toBytes();

      const account = this.#account;
      if (
        !account ||
        account.address !== address ||
        !bytesEqual(account.publicKey, publicKey)
      ) {
        this.#account = new FxWalletAccount({ address, publicKey });
        this.#emit('change', { accounts: this.accounts });
      }
    }
  };

  #disconnected = () => {
    if (this.#account) {
      this.#account = null;
      this.#emit('change', { accounts: this.accounts });
    }
  };

  #reconnected = () => {
    if (this.#fx.publicKey) {
      this.#connected();
    } else {
      this.#disconnected();
    }
  };

  #connect: StandardConnectMethod = async ({ silent } = {}) => {
    if (!this.#account) {
      await this.#fx.connect(silent ? { onlyIfTrusted: true } : undefined);
    }

    this.#connected();

    return { accounts: this.accounts };
  };

  #disconnect: StandardDisconnectMethod = async () => {
    await this.#fx.disconnect();
  };

  #signTransaction: SolanaSignTransactionMethod = async (...inputs) => {
    if (!this.#account) throw new Error('not connected');

    const outputs: SolanaSignTransactionOutput[] = [];

    if (inputs.length === 1) {
      const { transaction, account, chain } = inputs[0]!;
      if (account !== this.#account) throw new Error('invalid account');
      if (chain && !isSolanaChain(chain)) throw new Error('invalid chain');

      const signedTransaction = await this.#fx.signTransaction(
        VersionedTransaction.deserialize(transaction),
      );

      const serializedTransaction = isVersionedTransaction(signedTransaction)
        ? signedTransaction.serialize()
        : new Uint8Array(
            (signedTransaction as Transaction).serialize({
              requireAllSignatures: false,
              verifySignatures: false,
            }),
          );

      outputs.push({ signedTransaction: serializedTransaction });
    } else if (inputs.length > 1) {
      let chain: SolanaChain | undefined = undefined;
      for (const input of inputs) {
        if (input.account !== this.#account) throw new Error('invalid account');
        if (input.chain) {
          if (!isSolanaChain(input.chain)) throw new Error('invalid chain');
          if (chain) {
            if (input.chain !== chain) throw new Error('conflicting chain');
          } else {
            chain = input.chain;
          }
        }
      }

      const transactions = inputs.map(({ transaction }) =>
        VersionedTransaction.deserialize(transaction),
      );

      const signedTransactions = await this.#fx.signAllTransactions(
        transactions,
      );

      outputs.push(
        ...signedTransactions.map((signedTransaction) => {
          const serializedTransaction = isVersionedTransaction(
            signedTransaction,
          )
            ? signedTransaction.serialize()
            : new Uint8Array(
                (signedTransaction as Transaction).serialize({
                  requireAllSignatures: false,
                  verifySignatures: false,
                }),
              );

          return { signedTransaction: serializedTransaction };
        }),
      );
    }

    return outputs;
  };

  #signMessage: SolanaSignMessageMethod = async (...inputs) => {
    if (!this.#account) throw new Error('not connected');

    const outputs: SolanaSignMessageOutput[] = [];

    if (inputs.length === 1) {
      const { message, account } = inputs[0]!;
      if (account !== this.#account) throw new Error('invalid account');

      const { signature } = await this.#fx.signMessage(message);

      outputs.push({ signedMessage: message, signature });
    } else if (inputs.length > 1) {
      for (const input of inputs) {
        outputs.push(...(await this.#signMessage(input)));
      }
    }

    return outputs;
  };
}
