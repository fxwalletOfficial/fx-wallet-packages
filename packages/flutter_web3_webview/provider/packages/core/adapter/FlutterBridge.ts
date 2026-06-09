/**
 * Transport that hands provider requests to the Flutter side of the WebView.
 *
 * `flutter_web3_webview` registers a JavaScript handler named
 * `FxWalletHandler` (see `lib/src/webview.dart`) that delegates incoming
 * messages to `Web3RequestDispatcher`. Every provider request therefore
 * flows through `window.flutter_inappwebview.callHandler('FxWalletHandler',
 * payload)`; the Dart side resolves the returned `Promise` with the
 * dispatcher result or rejects it with an `Exception` string.
 *
 * The helper lives in `core` because both `ethereum` and `solana` need it
 * and re-implementing the guard / type declaration in each package would
 * drift over time.
 */

export const FLUTTER_HANDLER_NAME = 'FxWalletHandler' as const;

export interface FlutterCallHandler {
  callHandler(handlerName: string, ...args: unknown[]): Promise<unknown>;
}

export interface FlutterWebViewWindow {
  flutter_inappwebview?: FlutterCallHandler;
}

/**
 * Read `window.flutter_inappwebview` defensively. The provider bundle is
 * also bundled into unit tests that don't have a host WebView, so the
 * caller is expected to handle the `undefined` case rather than us
 * throwing eagerly at module load time.
 */
function getBridge(): FlutterCallHandler {
  const host = (
    typeof window !== 'undefined' ? (window as FlutterWebViewWindow) : null
  );
  const bridge = host?.flutter_inappwebview;
  if (!bridge) {
    // Match the wording the legacy bundle used so DApp-side error
    // matchers continue to work.
    throw new Error('Not init finished.');
  }
  return bridge;
}

export interface IFlutterBridgeArgs {
  method: string;
  params?: unknown;
}

/**
 * Sentinel that the Dart `Web3RpcError.toString()` prefixes onto its JSON
 * payload (see `lib/src/utils/web3_rpc_error.dart`).
 */
const WEB3_RPC_ERROR_SENTINEL = 'Web3RpcError: ';

/**
 * EIP-1193 `ProviderRpcError`. DApps branch on `error.code` (`4001`
 * user-rejected, `4902` unrecognized chain, `4200` unsupported method, …),
 * so the bridge re-throws this shape rather than the opaque wrapped string
 * the Flutter platform layer produces.
 */
export class ProviderRpcError extends Error {
  code: number;
  data?: unknown;

  constructor(code: number, message: string, data?: unknown) {
    super(message);
    this.name = 'ProviderRpcError';
    this.code = code;
    this.data = data;
  }
}

/**
 * The Dart side rejects with a `Web3RpcError` whose string form embeds
 * `Web3RpcError: {"code":...,"message":...}`. `flutter_inappwebview` wraps
 * that into a larger rejection string, so we locate the sentinel and parse
 * the trailing JSON back into a structured `ProviderRpcError`. Anything that
 * doesn't carry the sentinel (or whose payload doesn't parse) is returned
 * unchanged, so non-RPC failures surface as-is.
 */
function toProviderError(reason: unknown): unknown {
  const text =
    reason instanceof Error
      ? reason.message
      : typeof reason === 'string'
        ? reason
        : '';
  const at = text.lastIndexOf(WEB3_RPC_ERROR_SENTINEL);
  if (at === -1) return reason;

  const raw = text.slice(at + WEB3_RPC_ERROR_SENTINEL.length);
  // Trim any trailing characters the platform appended after the JSON.
  const end = raw.lastIndexOf('}');
  const json = end === -1 ? raw : raw.slice(0, end + 1);

  try {
    const parsed = JSON.parse(json) as {
      code?: number;
      message?: string;
      data?: unknown;
    };
    if (typeof parsed.code === 'number') {
      return new ProviderRpcError(
        parsed.code,
        parsed.message ?? 'Provider error',
        parsed.data,
      );
    }
  } catch {
    // Not the JSON we expected — fall through to the original reason.
  }
  return reason;
}

/**
 * Send `payload` to the wallet via the WebView bridge and return the
 * Dart-side response. Generic `T` is the expected response shape — the
 * helper does not enforce it at runtime, mirroring the upstream
 * `internalRequest` contract. Rejections that carry a `Web3RpcError`
 * sentinel are converted into a structured EIP-1193 `ProviderRpcError`.
 */
export function callFlutterHandler<T = unknown>(
  payload: IFlutterBridgeArgs,
): Promise<T> {
  return (
    getBridge().callHandler(FLUTTER_HANDLER_NAME, payload) as Promise<T>
  ).catch((reason) => {
    throw toProviderError(reason);
  });
}
