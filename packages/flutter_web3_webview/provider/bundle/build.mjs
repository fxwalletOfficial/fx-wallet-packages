#!/usr/bin/env node
/**
 * Build the single-file IIFE bundle that `flutter_web3_webview` injects into
 * every WebView page.
 *
 * Usage (from `provider/` root):
 *
 *   bun run build:flutter           # → ../lib/js/provider.min.js
 *   node bundle/build.mjs           # equivalent
 *   node bundle/build.mjs --watch   # rebuild on source changes
 *
 * The output target is intentionally the Flutter asset path so a successful
 * build refreshes the package in place; pubspec.yaml already declares it.
 */

import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import esbuild from 'esbuild';
import { polyfillNode } from 'esbuild-plugin-polyfill-node';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROVIDER_ROOT = path.resolve(__dirname, '..');
const FLUTTER_ASSET = path.resolve(
  PROVIDER_ROOT,
  '..',
  'lib',
  'js',
  'provider.min.js',
);

const args = new Set(process.argv.slice(2));
const watch = args.has('--watch');

/** @type {import('esbuild').BuildOptions} */
const config = {
  entryPoints: [path.join(__dirname, 'index.ts')],
  outfile: FLUTTER_ASSET,
  bundle: true,
  minify: true,
  // The WebView runtime that ships with flutter_inappwebview targets modern
  // Chromium / WebKit; ES2019 covers everything we need (async/await, optional
  // chaining, etc.) while staying conservative enough for older iOS WebKit.
  target: 'es2019',
  format: 'iife',
  platform: 'browser',
  // The aggregator self-installs onto `window.fxwallet`; we do not need a
  // global identifier for the IIFE return value.
  globalName: '__fxwalletProviderBundle',
  legalComments: 'none',
  logLevel: 'info',
  define: {
    // Solana's transitive deps gate development-only assertions behind
    // `process.env.NODE_ENV`. Force production so the minifier can elide them.
    'process.env.NODE_ENV': '"production"',
    // `global` is used by polyfilled Node libs (notably Buffer); alias it to
    // `globalThis` so the resulting IIFE works inside a sandboxed WebView.
    global: 'globalThis',
  },
  plugins: [
    polyfillNode({
      // Inject Buffer / process / globalThis where Node-style code expects
      // them. The Solana / web3.js / rpc-websockets stack relies on Buffer
      // pervasively, so leaving this off would break sign / send flows.
      globals: {
        buffer: true,
        process: true,
        global: true,
      },
      // Pull in the polyfill for the Node built-ins the upstream Solana stack
      // (transitively) imports. Anything not listed here is shimmed to an
      // empty module by the plugin's default, which is what we want for
      // dead-code branches like `fs` / `tls` that should never run in browser.
      polyfills: {
        buffer: true,
        crypto: true,
        events: true,
        http: true,
        https: true,
        stream: true,
        url: true,
        util: true,
        zlib: true,
      },
    }),
  ],
};

if (watch) {
  const ctx = await esbuild.context(config);
  await ctx.watch();
  console.log(`Watching for changes; output: ${FLUTTER_ASSET}`);
} else {
  const result = await esbuild.build(config);
  if (result.errors.length) {
    console.error(`Build failed with ${result.errors.length} errors.`);
    process.exit(1);
  }
  console.log(`Wrote ${FLUTTER_ASSET}`);
}
