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
 * Send `payload` to the wallet via the WebView bridge and return the
 * Dart-side response. Generic `T` is the expected response shape — the
 * helper does not enforce it at runtime, mirroring the upstream
 * `internalRequest` contract.
 */
export function callFlutterHandler<T = unknown>(
  payload: IFlutterBridgeArgs,
): Promise<T> {
  return getBridge().callHandler(
    FLUTTER_HANDLER_NAME,
    payload,
  ) as Promise<T>;
}
