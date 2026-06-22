# PR6 spec — `aleo_flutter` plugin + prebuilt-binary distribution

> Status: this is the ORIGINAL plan (spec-first per the project's churn lesson),
> kept for the record. It is **partly superseded by the implementation** — most
> importantly **iOS now ships a DYNAMIC framework, not a static lib**, so the
> static-lib / `DynamicLibrary.process()` / dead-strip / `-force_load` material
> below (§3 run-time row, §7.4) NO LONGER reflects the build. The as-built design
> is in [`pr6a-impl-notes.md`](pr6a-impl-notes.md) ("Round 4 — iOS switched to a
> DYNAMIC framework"). Decisions §2 and the build-time-fetch model still hold.
> Target branch `epic/aleo-dart-monorepo` (base `82b1dcf`, Phase 4 complete).

## 0. Applicable baseline

- Phase 4 is merged: `aleo_ffi` is clean-room Apache-2.0, links no HTTP/TLS stack,
  carries no GPL; 34 FFI symbols; `ffi_abi_version` load guard; `AleoLib.coerce`
  validates the lib at every public constructor.
- `aleo_dart` is a **pure Dart package** (no Flutter dep). It already loads via
  `DyLib.getDyLibFromCargo()` (desktop) / `DyLib.getMobileDyLib()` (Android open /
  iOS process()) — the loading model PR6 reuses unchanged.
- The native lib `libaleo_rust` is **~35 MB/platform**. Building it from source per
  consumer is the pain PR6 removes.
- **Proving is server-delegated** in the wallet (the in-repo `wss_demo.dart` /
  `wss_delegation_demo.dart` send the authorization to `.../wallet/aleo/delegate`;
  the server proves). So the client only runs the *cheap* offline ops
  (authorize / fee-auth / account / record / broadcast). The ~1.15 GB proving keys
  and `ParameterProvisioner` are NOT in the client path under delegation.

## 1. Goal & non-goals

**Goal:** consume the native library as a normal dependency — the consumer app
`flutter build`s and the right `libaleo_rust` is bundled automatically, no `cargo`,
no `build_*.sh`, works on simulators/emulators and devices, offline at runtime.

**Non-goals (explicitly out of PR6):**
- Client-side self-proving / the ~1.15 GB proving keys (server-delegated; and
  `ParameterProvisioner` already handles it as an optional path if ever needed).
- Desktop Flutter plugin (macOS/Windows/Linux) — desktop dev keeps
  `getDyLibFromCargo` (build from source).
- Public pub.dev publication (see Decision 3 — internal git dependency first).

## 2. Decisions (defaults below; flag any to change before coding)

| # | Decision | Default (recommended) |
|---|---|---|
| 1 | Proving model on device | **delegate-only** — client never bundles/downloads proving keys; PR6 ships only the ~35 MB lib |
| 2 | Packaging form | **B — a new `aleo_flutter` Flutter FFI plugin**; `aleo_dart` stays pure Dart, untouched |
| 3 | Distribution channel | **internal git dependency pinned to a tag** (not public pub.dev yet) |
| 4 | Artifact hosting + version binding | **GH Releases on `fxwalletOfficial/fx-wallet-packages`**, tag `aleo_ffi-vX.Y.Z`, per-platform SHA-256 **pinned in the plugin package** |
| 5 | Platforms | **Android + iOS** (desktop = build-from-source) |
| 6 | Release CI runners | **GitHub-hosted** (ubuntu+NDK for Android, macOS+Xcode for iOS) — free on a public repo |
| 7 | License of the binary-shipping plugin | **`aleo_flutter` = Apache-2.0** + bundled `NOTICE`/`THIRD_PARTY_LICENSES`; `aleo_dart` stays MIT |

## 3. Architecture — build-time fetch, NOT runtime

The single most important point (and a common misconception):

| Phase | Who / where | What happens |
|---|---|---|
| **Build time** | dev machine / CI, during `flutter build` / `pod install` / Gradle | the plugin downloads the prebuilt `libaleo_rust` from GH Releases **once** (cached), verifies its SHA-256, and bundles it INTO the app (Android `jniLibs`; iOS embeds the dynamic `AleoRust.framework` via xcframework — *as built*; the original plan said static) |
| **Run time** | end-user device | `AleoFlutter.load()` = `DynamicLibrary.open('libaleo_rust.so')` (Android) / `DynamicLibrary.open('AleoRust.framework/AleoRust')` (iOS — *as built*; the original plan said `process()`) + `AleoLib` validate → **local, instant, no network, offline-safe** |

The end user never downloads the native lib. `load()` does no I/O — it is effectively
synchronous (dlopen + version check); it must not imply a network call.

## 4. `packages/aleo_flutter` layout

```
packages/aleo_flutter/
├── pubspec.yaml          # deps: flutter, aleo_dart; flutter.plugin.platforms {android:{ffiPlugin:true}, ios:{ffiPlugin:true}}
├── lib/aleo_flutter.dart # AleoFlutter.load() -> validated DynamicLibrary; re-export aleo_dart's public API
├── lib/src/artifact_manifest.dart  # const map {platform -> {url, sha256}} pinned to this version (the integrity anchor, §5)
├── android/build.gradle  # task: download per-ABI .so from GH Releases -> verify sha256 -> jniLibs (build time)
├── ios/aleo_flutter.podspec  # prepare_command: download xcframework -> verify sha256 -> vendored_frameworks + dead-strip retention
├── NOTICE / THIRD_PARTY_LICENSES   # §8
└── example/              # minimal Flutter app — the simulator/emulator + device acceptance harness (§9)
```

**Public Dart API (thin):**
```dart
class AleoFlutter {
  /// Returns the bundled native library, ABI-validated. No network, no I/O beyond
  /// dlopen — the library is already inside the app (bundled at build time).
  static AleoLib load() => AleoLib.fromDynamicLibrary(DyLib.getMobileDyLib());
}
// + re-export of aleo_dart so the app imports one package.
```
The app then uses the unchanged `aleo_dart` API: `AleoAccount(lib.dyLib, net)`, etc.
(Or the constructors accept the `AleoLib` directly via `coerce`.)

## 5. Artifact, hosting, integrity, version binding

- **Naming**: release tag `aleo_ffi-vX.Y.Z`; assets e.g. `libaleo_rust-android.zip`
  (the 3 `jniLibs/<abi>/libaleo_rust.so`) and `AleoRust.xcframework.zip`.
- **Integrity anchor IN the package** (early-review F5): `artifact_manifest.dart`
  holds the per-asset **SHA-256** pinned to this plugin version. The Gradle/podspec
  download verifies against it. A same-origin checksum is NOT an anchor.
- **Version binding (easy-to-miss #1)**: the plugin version ↔ the `aleo_ffi-vX.Y.Z`
  tag it downloads ↔ the `ffi_abi_version` baked into that build must all line up.
  The plugin downloads a **pinned** tag (never "latest"). `AleoLib`'s runtime guard
  is the backstop, but the build must fetch the matching artifact.

## 6. Release pipeline (new workflow, e.g. `.github/workflows/release-aleo.yml`)

Trigger: push of a tag `aleo_ffi-v*`. Jobs (GitHub-hosted, free on public repo):
- **android**: `ubuntu-latest` + NDK + cargo-ndk → `rust/build_android.sh` → zip the
  3 ABIs.
- **ios**: `macos-latest` + Xcode + the ios rust targets → `rust/build_ios.sh` → zip
  `AleoRust.xcframework`.
- **publish**: compute SHA-256 of each asset, attach assets to the GH Release for the
  tag, and emit the checksums (used to update `artifact_manifest.dart`).
- The build scripts already exist (PR4b) and are locally verified; this PR wires them
  into CI on tag.

## 7. Easy-to-miss checklist (carried from the planning round, scoped to the chosen approach)

1. **Version triple-binding** (plugin ver ↔ tag ↔ `ffi_abi_version`) — pin, don't use latest. (§5)
2. **In-package SHA-256 anchor** — `artifact_manifest.dart`; verify after download. (§5)
3. **Monorepo tag namespacing** — `aleo_ffi-vX.Y.Z` so it doesn't collide with other packages' future releases.
4. **iOS static-lib + plugin + `process()` (highest risk)** — **SUPERSEDED: solved by shipping a DYNAMIC framework instead (see `pr6a-impl-notes.md` "Round 4"); the static-lib dead-strip problem below no longer applies.** *(original concern, kept for the record:)* the xcframework was a *static* lib; linked into the app the `#[no_mangle]` symbols get dead-stripped and `DynamicLibrary.process()` finds nothing. The podspec must retain them (`-force_load` the resolved slice, or `-exported_symbols_list`, or `DEAD_CODE_STRIPPING=NO`); the exact mechanism that works through CocoaPods + an xcframework needs **real-build experimentation** + an `nm` check on the final app binary. This was the make-or-break detail — and four real-build failures are exactly why it moved to a dynamic framework.
5. **Android Gradle** — `minSdk`, `jniLibs` packaging (`useLegacyPackaging`), the download task ordering/caching, 16k-aligned `.so`.
6. **License/attribution** — ship the bundled lib's Apache LICENSE + `NOTICE`/`THIRD_PARTY_LICENSES` (snarkVM Apache + transitive MIT/BSD/Unicode; elect Apache/MIT for r-efi). (§8)
7. **Release CI needs macOS + NDK** — GitHub-hosted, free on public repo; do not put fork-PR builds on self-hosted.
8. **`dart pub publish` warning** — `lib/aleo.dart` vs package name (pre-existing) — only matters if/when we publish; not blocking for git-dep.
9. **Internal git dep vs pub.dev** — git+pinned-tag gives the "no compile" experience without a public publish commitment. (Decision 3)
10. **Don't break existing API** — `DyLib.*` / `AleoLib` / `getMobileDyLib` stay; `aleo_flutter` only adds a convenience entry.
11. **melos / CI integration** — new package + example app in `melos bootstrap`; `ci.yml`'s `flutter test` now includes the plugin/example.
12. **example app = the real verification** — load + a cheap API call on iOS simulator + Android emulator + a device. (§9)

## 8. License & attribution

- `aleo_flutter` → **Apache-2.0** (matches the binary it ships + adds a patent grant).
  `aleo_dart` (and the other monorepo packages) stay MIT — per-package licensing is
  fine; flag if you instead want the whole monorepo relicensed.
- Bundle, alongside the binary: `aleo_ffi`'s Apache-2.0 LICENSE/NOTICE and a generated
  `THIRD_PARTY_LICENSES` (e.g. `cargo about`) covering the statically-linked snarkVM
  (Apache-2.0) + transitive deps; document electing Apache/MIT for `r-efi`'s
  `Apache OR LGPL OR MIT`. Not legal advice — confirm with whoever owns IP/legal.

## 9. Verification / acceptance criteria

- `example/` Flutter app, in CI and locally:
  - **Android emulator (x86_64) + iOS simulator** + at least one **physical device**:
    `AleoFlutter.load()` succeeds, `ffi_abi_version` passes, and a cheap API call
    (e.g. mnemonic→address, or `executionAuthorization`) returns a valid result.
    **The simulator/emulator run is a hard acceptance gate** (it is exactly what was
    impossible before — the multi-slice xcframework + Android x86_64/arm64 fix it).
  - `nm` on the final iOS app binary shows the FFI symbols survived dead-strip (§7.4).
  - Runtime load works **offline** (airplane mode) — proves no runtime download.
  - A deliberately mismatched lib → `IncompatibleNativeLibraryException` at load.
- The release workflow produces the assets + checksums on a `aleo_ffi-v*` tag.

## 10. Suggested PR split (PR6 is sizable)

- **PR6a** — the `aleo_flutter` plugin skeleton: pubspec/plugin decl, `lib` API,
  android Gradle fetch, ios podspec fetch + the dead-strip solution, example app,
  manifest (pointing at a manually-uploaded first release), melos/CI wiring.
  Verified on simulator/emulator/device. (The risky iOS §7.4 work lands here.)
- **PR6b** — the release pipeline workflow + checksum/version-binding automation +
  the THIRD_PARTY_LICENSES generation.

## 11. Future (beyond PR6)

- Public pub.dev publication (resolve the naming warning + finalize licensing).
- Client-side self-proving distribution (the ~1.15 GB proving keys) if the wallet
  ever moves off server delegation — already designed via `ParameterProvisioner`.
- Desktop Flutter plugin platforms; migration to Dart native assets when stable.
