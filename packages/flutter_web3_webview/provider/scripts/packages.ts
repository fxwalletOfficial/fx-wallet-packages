/**
 * List of packages that are able to build and distribute.
 *
 * The FxWallet vendored copy only ships the chains we actually expose through
 * the Flutter WebView (`ethereum`, `solana`, and the shared `core`). If a new
 * chain is brought online, add it here and import it from the bundle entry.
 */
export const allowedPackages = ['core', 'ethereum', 'solana'];
