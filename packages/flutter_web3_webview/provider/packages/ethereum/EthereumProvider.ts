import type IEthereumProvider from './types/EthereumProvider';

import type { IPermissionRes, IRequestArguments } from './types';

import { BaseProvider, callFlutterHandler } from '@fxwallet/web3-provider-core';
import type { IEthereumProviderConfig } from './types/EthereumProvider';
import { RPCError } from './exceptions/RPCError';
// `MobileAdapter` is still vendored in `./MobileAdapter.ts` for reference
// but is not on the request hot path — see the `internalRequest` /
// `request` doc-block below. Importing it would force esbuild to keep the
// adapter's `method:"signTransaction"` / `method:"signPersonalMessage"` /
// etc. case literals in the final bundle, which is misleading because the
// Dart `Web3RequestDispatcher` switches on the original `eth_*` names.
import { RPCServer } from './RPCServer';

export class EthereumProvider
  extends BaseProvider
  implements IEthereumProvider
{
  static NETWORK = 'ethereum';

  // should be hex
  #chainId!: string;

  #rpcUrl!: string;

  #overwriteMetamask = false;

  #address!: string;

  #rpc!: RPCServer;

  // True after setRPC(…) installs a custom transport (e.g. NativeRPC). When
  // set, subsequent setRPCUrl(…) calls update the stored URL but must NOT
  // replace the RPC instance — otherwise chain switches silently revert to
  // fetch() and trip the page CSP.
  #customRpc: boolean = false;

  isFxWallet: boolean = true;

  providers: object[] | undefined;

  constructor(config?: IEthereumProviderConfig) {
    super();
    this.request = this.request.bind(this);

    if (config) {
      if (config.chainId) {
        this.#chainId = config.chainId;
      }

      if (config.rpc || config.rpcUrl) {
        this.#rpcUrl = config.rpc || config.rpcUrl!;
      }

      if (typeof config.overwriteMetamask !== 'undefined') {
        this.#overwriteMetamask = config.overwriteMetamask;
      }

      if (typeof config.isFxWallet !== 'undefined') {
        this.isFxWallet = config.isFxWallet;
      }

      this.#rpc = new RPCServer(this.#rpcUrl);
    }

    super.on('onResponseReady', this.onResponseReady.bind(this));
    this.connect();
  }

  /**
   * Emit connect event with ProviderConnectInfo
   */
  private connect() {
    this.emit('connect', { chainId: this.#chainId });
  }

  /**
   * Forward a wallet-initiated chain switch to subscribed DApps.
   *
   * `lib/src/utils/request_dispatcher.dart` calls
   * `window.ethereum.emitChainChanged(chainId)` from
   * `_walletSwitchEthereumChain` so DApps that listen via EIP-1193's
   * `chainChanged` event (or the legacy `networkChanged` alias still used
   * by older libraries) refresh their state immediately. The Dart side
   * passes a `0x`-prefixed hex chain id, matching the EIP-1193 contract.
   */
  public emitChainChanged(chainId: string) {
    this.#chainId = chainId;
    this.emit('chainChanged', chainId);
    this.emit('networkChanged', chainId);
  }

  /**
   * Emit the EIP-1193 `accountsChanged` event for the currently selected
   * accounts. Exposed publicly so the Flutter side can notify DApps when
   * the user switches wallets without reloading the page.
   */
  public emitAccountsChanged(accounts: string[]) {
    this.emit('accountsChanged', accounts);
  }

  /**
   * @deprecated
   * @returns
   */
  public enable(): Promise<string[]> {
    return this.request<string[]>({ method: 'eth_requestAccounts' });
  }

  /**
   * sendAsync
   *
   * @deprecated
   * @param args
   * @param callback
   */
  sendAsync(
    args: IRequestArguments,
    callback: (error: any | null, data: unknown | null) => void,
  ): void {
    if (Array.isArray(args)) {
      Promise.all(args.map((payload) => this.request(payload)))
        .then((data) => callback(null, data))
        .catch((error) => callback(error, null));
    } else {
      this.request(args)
        .then((data) => callback(null, data))
        .catch((error) => callback(error, null));
    }
  }

  /**
   * @deprecated Use request() method instead.
   */
  _send(payload: IRequestArguments) {
    const response: { result: any; jsonrpc: string } = {
      jsonrpc: '2.0',
      result: null,
    };

    switch (payload.method) {
      case 'eth_accounts':
      case 'eth_coinbase':
        response.result = this.handleStaticRequests({
          method: 'eth_accounts',
        }) as any;
        break;

      case 'net_version':
      case 'eth_chainId':
        // The chain id isn't cached on the provider in this pass-through
        // design — it's served by the Dart `ethChainId` callback over the
        // async `request` path — so there's no correct synchronous answer
        // here. (Previously this wrongly returned the accounts array.)
        throw new RPCError(
          4200,
          `FxWallet does not support calling ${payload.method} synchronously. Use request({ method: '${payload.method}' }) instead.`,
        );

      default:
        throw new RPCError(
          4200,
          `FxWallet does not support calling ${payload.method} synchronously without a callback. Please provide a callback parameter to call ${payload.method} asynchronously.`,
        );
    }

    return response;
  }

  /**
   * @deprecated Use request() method instead.
   */
  send(methodOrPayload: unknown, callbackOrArgs?: unknown): unknown {
    if (
      typeof methodOrPayload === 'string' &&
      (!callbackOrArgs || Array.isArray(callbackOrArgs))
    ) {
      const context = this;

      return new Promise((resolve, reject) => {
        try {
          const req = context.request({
            method: methodOrPayload,
            params: callbackOrArgs as unknown[],
          });

          if (req instanceof Promise) {
            req.then(resolve).catch(reject);
          } else {
            resolve(req);
          }
        } catch (error) {
          reject(error);
        }
      });
    } else if (
      methodOrPayload &&
      typeof methodOrPayload === 'object' &&
      typeof callbackOrArgs === 'function'
    ) {
      return this.request(methodOrPayload as IRequestArguments).then(
        callbackOrArgs as (...args: unknown[]) => void,
      );
    }

    return this._send(methodOrPayload as IRequestArguments);
  }

  /**
   * Forward the request to the Flutter side untouched.
   *
   * Both `request` and `internalRequest` are single-step pass-throughs:
   * the Dart `Web3RequestDispatcher` (see
   * `lib/src/utils/request_dispatcher.dart`) is the source of truth for
   * which EIP-1193 method names are supported and how their params are
   * parsed, so the JS layer is intentionally a thin transport that does
   * **not** rewrite the DApp's `{ method, params }` payload.
   *
   * The upstream design routed every request through `MobileAdapter`,
   * which renames `eth_sendTransaction → signTransaction`, `personal_sign
   * → signPersonalMessage`, `wallet_switchEthereumChain →
   * switchEthereumChain`, and similar; the Dart dispatcher switches on
   * the original `eth_*` / `personal_*` / `wallet_*` names, so those
   * renames would otherwise fall through to `_defaultCallback`. The
   * upstream's `handleStaticRequests` (which short-circuits
   * `eth_chainId` / `eth_accounts` against cached state) is also skipped
   * here so the wallet remains the authoritative source for both — this
   * matches the legacy `provider.min.js` exactly, and the Dart
   * dispatcher already marks those two methods `isImmediate` so the
   * round-trip is cheap.
   *
   * `MobileAdapter` is left vendored under `provider/packages/ethereum/`
   * for reference and possible future use, but is intentionally off the
   * hot path.
   */
  internalRequest<T>(args: IRequestArguments): Promise<T> {
    return callFlutterHandler<T>(args);
  }

  request<T>(args: IRequestArguments): Promise<T> {
    return this.internalRequest<T>(args);
  }

  /**
   * Methods that don't require reaching the handler
   * @param args
   * @param next
   * @returns
   */
  private handleStaticRequests<T>(
    args: IRequestArguments,
    next?: () => Promise<T>,
  ): Promise<T> | T | undefined {
    switch (args.method) {
      case 'net_version':
        return (this.#chainId
          ? parseInt(this.#chainId)
          : undefined) as unknown as unknown as T;
      case 'eth_chainId':
        return this.#chainId as unknown as T;
      case 'eth_accounts':
      case 'eth_coinbase':
        return (this.#address ? [this.#address] : []) as unknown as T;
    }
    if (next) {
      return next();
    }
  }

  /**
   * The provider needs to be stateful for certain request such as
   * storing the user's address after a eth_requestAccounts, this is for
   * mobile compatibility
   *
   * @param req
   * @param response
   * @returns
   */
  private onResponseReady(req: IRequestArguments, response: unknown) {
    if (!response) {
      return;
    }

    switch (req.method) {
      case 'eth_requestAccounts':
      case 'requestAccounts':
        this.#address = (response as string[])[0];
        break;
      case 'wallet_requestPermissions':
        this.#address = (
          response as IPermissionRes[]
        )[0]?.caveats?.[0]?.value?.[0];
        break;
    }
  }

  getNetwork() {
    return EthereumProvider.NETWORK;
  }

  get connected(): boolean {
    return true;
  }

  get isMetaMask(): boolean {
    return this.#overwriteMetamask;
  }

  getChainId() {
    return this.#chainId;
  }

  getNetworkVersion() {
    return this.handleStaticRequests({
      method: 'net_version',
    }) as number | undefined;
  }

  public setChainId(chainId: string) {
    this.#chainId = chainId;
  }

  public setRPCUrl(rpcUrl: string) {
    this.#rpcUrl = rpcUrl;
    if (!this.#customRpc) {
      this.#rpc = new RPCServer(this.#rpcUrl);
    }
  }

  public getRPC() {
    return this.#rpc;
  }

  public setOverwriteMetamask(overwriteMetamask: boolean) {
    this.#overwriteMetamask = overwriteMetamask;
  }

  public getAddress() {
    return this.#address;
  }

  public setAddress(address: string) {
    this.#address = address;
  }

  setRPC(rpc: any) {
    this.#rpc = rpc;
    this.#customRpc = true;
  }
}
