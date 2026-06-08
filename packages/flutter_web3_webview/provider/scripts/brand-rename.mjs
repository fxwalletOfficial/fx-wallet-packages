#!/usr/bin/env node
/**
 * Apply the FxWallet brand rename across the vendored Trust Web3 Provider
 * source tree. Idempotent: re-running on an already-renamed tree is a no-op.
 *
 * Usage (from `provider/` root):
 *
 *   node scripts/brand-rename.mjs            # rewrite files in place
 *   node scripts/brand-rename.mjs --check    # exit 1 if anything would change
 *
 * The intent is to make a future `git subtree pull` / manual upstream rebase
 * cheap — after merging upstream we just re-run this script to re-apply the
 * rename instead of having to remember every replacement by hand.
 */

import { promises as fs } from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

// Directories that should never be rewritten — generated artifacts, deps,
// VCS state, and anything our own tooling owns.
const SKIP_DIRS = new Set([
  'node_modules',
  'dist',
  '.git',
  '.github',
  '.vscode',
  'coverage',
]);

// Files / extensions to leave alone. `UPSTREAM.md` and `RECOVERY.md`
// document what was renamed / still needs to be ported and intentionally
// reference the upstream repository names; they must survive future re-runs
// of this script.
const SKIP_FILES = new Set([
  'brand-rename.mjs',
  'UPSTREAM.md',
  'RECOVERY.md',
  'bun.lock',
  'bun.lockb',
  'yarn.lock',
  'package-lock.json',
  'pnpm-lock.yaml',
  '.gitattributes',
]);
const BINARY_EXTENSIONS = new Set([
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.ico',
  '.svg',
  '.lockb',
  '.woff',
  '.woff2',
  '.ttf',
]);

// Replacement table. Order matters — apply the longest / most specific
// patterns first so the catch-all `trustwallet → fxwallet` does not corrupt a
// namespaced package id before it has been rewritten.
const REPLACEMENTS = [
  // 1. npm package identifiers
  ['@trustwallet/web3-provider-core', '@fxwallet/web3-provider-core'],
  ['@trustwallet/web3-provider-ethereum', '@fxwallet/web3-provider-ethereum'],
  ['@trustwallet/web3-provider-solana', '@fxwallet/web3-provider-solana'],
  ['@trustwallet/web3-provider', '@fxwallet/web3-provider'],

  // 2. Author / contact metadata
  ['Trust <support@trustwallet.com>', 'fxwalletOfficial <noreply@fxwallet.io>'],
  ['support@trustwallet.com', 'noreply@fxwallet.io'],

  // 3. Provider feature flags (DApps sniff these to recognise the wallet).
  //    Keep these BEFORE the bare `TrustWallet` / `Trust` replacements.
  [/\bisTrustWallet\b/g, 'isFxWallet'],
  [/\bisTrust\b/g, 'isFxWallet'],

  // 4. Human-readable phrases that lose meaning under a blind `Trust → FxWallet`.
  ['Trust Web3 Provider', 'FxWallet Web3 Provider'],
  ['Trust web3 Provider', 'FxWallet web3 Provider'],

  // 5. CamelCase and lower-case brand tokens. Lookahead allows CamelCase
  //    continuation (e.g. `TrustWalletAccount` → `FxWalletAccount`) without
  //    matching `Trustworthy` or similar unrelated identifiers.
  [/\bTrustWallet(?=[A-Z]|\b)/g, 'FxWallet'],
  [/\btrustwallet\b/g, 'fxwallet'],

  // 6. Solana wallet-standard namespace identifier. The current
  //    `provider.min.js` exposes this as `'fxwallet:'` rather than the
  //    upstream `'trust:'`, with the matching `TrustNamespace` /
  //    `TrustFeature` symbols renamed to the `Fx*` form.
  ['TrustNamespace', 'FxNamespace'],
  ['TrustFeature', 'FxFeature'],
  ["'trust:'", "'fxwallet:'"],
  ['"trust:"', '"fxwallet:"'],

  // 7. Lone `Trust` (uppercase). Inventoried occurrences are all brand
  //    references — `Trust's RPC subdomain`, the Solana wallet
  //    `#name = 'Trust'`, the EthereumProvider sync-call error message,
  //    README titles, and `package.json` `author` fields.
  [/\bTrust\b/g, 'FxWallet'],

  // 8. Lone `trust` (lowercase). Only occurs as the identifier name
  //    threaded through `solana/adapter/wallet.ts` + `initialize.ts`
  //    (constructor param, the `#trust` private field, the inner
  //    `[FxNamespace]: { trust: … }` key). The minified bundle renames
  //    these to `fx`, so mirror that to keep the wallet-standard feature
  //    shape compatible. The regex relies on word boundaries so common
  //    English vocabulary like `onlyIfTrusted` is left untouched.
  [/\btrust\b/g, 'fx'],

  // 9. Upstream declares two aliased provider flags — `isTrust` and
  //    `isTrustWallet` — and mirrors both in the constructor config
  //    plumbing. Both collapse to `isFxWallet`, producing duplicate field
  //    declarations and assignments that TypeScript rejects with TS2300.
  //    Collapse the resulting redundant lines back to a single one. The
  //    pattern is anchored on the exact upstream indentation; if upstream
  //    reformats, the patterns need to be updated, which is intentionally
  //    explicit so a silent regression is visible.
  [
    /(\n[ \t]*isFxWallet: boolean = true;)\s*\1\s*\n/g,
    '$1\n\n',
  ],
  [
    /(\n[ \t]*this\.isFxWallet = config\.isFxWallet;)\s*\1\s*\n/g,
    '$1\n',
  ],
];

const args = new Set(process.argv.slice(2));
const checkOnly = args.has('--check');

let scanned = 0;
let changed = 0;
const changedFiles = [];

async function walk(dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      await walk(full);
      continue;
    }
    if (!entry.isFile()) continue;
    if (SKIP_FILES.has(entry.name)) continue;
    const ext = path.extname(entry.name).toLowerCase();
    if (BINARY_EXTENSIONS.has(ext)) continue;
    await processFile(full);
  }
}

async function processFile(file) {
  scanned += 1;
  const original = await fs.readFile(file, 'utf8');
  let rewritten = original;
  for (const [pattern, replacement] of REPLACEMENTS) {
    if (typeof pattern === 'string') {
      rewritten = rewritten.split(pattern).join(replacement);
    } else {
      rewritten = rewritten.replace(pattern, replacement);
    }
  }
  if (rewritten === original) return;
  changed += 1;
  changedFiles.push(path.relative(ROOT, file));
  if (checkOnly) return;
  await fs.writeFile(file, rewritten);
}

await walk(ROOT);

console.log(`Scanned ${scanned} files, ${changed} ${checkOnly ? 'would change' : 'rewritten'}.`);
if (changedFiles.length) {
  for (const file of changedFiles) console.log('  -', file);
}
if (checkOnly && changed > 0) process.exit(1);
