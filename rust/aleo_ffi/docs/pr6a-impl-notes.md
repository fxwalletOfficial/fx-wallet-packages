# PR6a implementation notes — `aleo_flutter` plugin skeleton

> Companion to `pr6-distribution-spec.md`. Records the decisions made while
> building the `packages/aleo_flutter` skeleton, the highest-risk item (iOS
> static-lib dead-strip), and what is deferred to the stage-2 real-build
> verification. Spec-first per the project's churn lesson.

## What PR6a delivers (stage 1, this commit)

The `packages/aleo_flutter` Flutter FFI plugin, scaffolded from
`flutter create --template=plugin_ffi` and then converted from *compile-native-
from-source* to *bundle-a-prebuilt-binary*:

- `pubspec.yaml` — `flutter.plugin.platforms.{android,ios}.ffiPlugin: true`;
  depends on `aleo_dart` (path). The native build-from-source template bits
  (`src/`, `ios/Classes/*.c`, ffigen, generated bindings) were deleted.
- `lib/aleo_flutter.dart` — `AleoFlutter.load()` = `AleoLib.coerce(DyLib.getMobileDyLib())`;
  re-exports the full `aleo_dart` API so an app imports one package.
- `lib/src/artifact_manifest.dart` — the in-package integrity anchor (URLs +
  SHA-256 + release tag + ABI version), as flat literal consts.
- `android/build.gradle` + `android/download_artifact.sh` — fetch per-ABI
  `libaleo_rust.so` into a `jniLibs` source set at build time.
- `ios/aleo_flutter.podspec` + `ios/download_artifact.sh` — fetch
  `AleoRust.xcframework`, vendor it, and apply the dead-strip retention flag.
- `example/` — a runnable app whose one button loads the bundled library and runs
  a cheap, offline API (`mnemonicToAddress`). This is the stage-2 acceptance
  harness (spec §9).
- `LICENSE` (Apache-2.0), `NOTICE`, `THIRD_PARTY_LICENSES.md`.
- Tests that run without the native library (manifest invariants; example smoke).

NOT in stage 1: the actual native builds, the on-device run, and the `nm` symbol
check — those are stage 2 (they need heavy iOS/Android builds).

## Decision 1 — iOS dead-strip retention = `-force_load` (the make-or-break)

> **SUPERSEDED (round 4 — see below): iOS now ships a DYNAMIC framework, not a
> static lib.** After three real-build failures rooted in static linking (slice
> filename, `-force_load` not reaching the Runner, then `-force_load` referencing a
> build-time intermediate that breaks clean builds), the whole dead-strip class was
> removed by switching to a dynamic framework. The analysis below is kept for the
> record; the live mechanism is in "Round 4" near the end.

`AleoRust.xcframework` is a **static** archive. The crucial fact:

- A static linker only pulls archive members whose symbols are **referenced**.
- Nothing in the app references the `#[no_mangle]` exports directly — they are
  resolved at runtime via `DynamicLibrary.process()`.
- So by default those members are **never pulled into the app binary**, and
  `process()` finds nothing → runtime lookup failures.

Of the three candidate mechanisms (spec §7.4):

| Mechanism | Verdict |
|---|---|
| `DEAD_CODE_STRIPPING=NO` | **Insufficient alone.** It prevents stripping *after* member selection, but unreferenced archive members are never *selected* to begin with. |
| `-exported_symbols_list` | Controls what is exported, not whether members are pulled; still needs the members in. |
| **`-force_load <archive>`** | **Correct.** Forces every object file from the archive in, so all exports survive. |

Implemented in the podspec as
`OTHER_LDFLAGS = -force_load "${PODS_XCFRAMEWORKS_BUILD_DIR}/aleo_flutter/libaleo_rust.a"`.

**Open (stage 2):** the exact `${PODS_XCFRAMEWORKS_BUILD_DIR}` subpath that
CocoaPods uses for an xcframework's extracted per-SDK slice must be confirmed
against a real `pod install` + build, then verified on the final app binary:

```
nm -gU "$BUILT_PRODUCTS_DIR/Runner.app/Runner" | grep -E 'ffi_abi_version|execute_proof_checked'
```

Both symbols must be present. If `-force_load` with that path does not work
through CocoaPods + xcframework, fall back candidates in order: per-slice
`vendored_libraries` with an `[sdk=...]`-conditioned `-force_load`, then an
`-exported_symbols_list` combined with forcing the members.

## Decision 2 — local-build override, then download (dev/CI before a release)

There is no GitHub Release yet (PR6b builds the pipeline). Both platform scripts
resolve the artifact in this order:

1. **Local build** — `$ALEO_FFI_IOS_XCFRAMEWORK` / `$ALEO_FFI_ANDROID_JNILIBS`,
   else the `rust/build_ios.sh` / `rust/build_android.sh` default outputs
   (`rust/ios_lib/AleoRust.xcframework`, `rust/android_lib/jniLibs`).
2. **Download + verify** — fetch the pinned release asset and check its SHA-256
   against the manifest.

This makes the plugin buildable/testable now (stage 2 builds locally) and in
production later (consumers download), with one code path. An all-zero manifest
SHA-256 is treated as "unset" → step 2 errors with guidance, so a missing local
build never silently ships an unverified binary. SHA-256 is computed with
`sha256sum` (Linux) or `shasum -a 256` (macOS), whichever is present, and each
script asserts the expected layout after unzip.

**Where the fetch is invoked (self-review fix):**
- iOS: from the **podspec body**, NOT `prepare_command`. CocoaPods runs
  `prepare_command` only for pods it *downloads*; Flutter integrates plugins as
  `:path` (development) pods, which are never downloaded, so `prepare_command`
  would silently not run and the xcframework would be missing. The podspec body is
  evaluated for every pod on every `pod install` (path included), so the fetch
  runs there (`system('bash', "#{__dir__}/download_artifact.sh")`), before
  CocoaPods globs `vendored_frameworks`.
- Android: from a Gradle `Exec` task wired before `preBuild`. The local source dir
  is declared as a task input when present, so a rebuilt `.so` re-triggers the
  copy (no stale-library caching).

## Decision 3 — manifest is the anchor; build tools parse the `.dart`

The integrity anchor lives in `lib/src/artifact_manifest.dart` (spec §5). The
Gradle (Groovy) and podspec (Ruby/shell) layers cannot import Dart, so the
`download_artifact.sh` scripts parse the values out of the `.dart` source. The
consts are kept **flat and literal** (no string interpolation) so a single
`const String NAME = '...'` pattern is unambiguous — but note `dart format` wraps
the long URL/SHA lines after `=`, so the extractor must span the newline (a
`perl -0777` slurp with `\s*` between `=` and the string; perl ships on macOS and
the GitHub ubuntu/macos runners). A plain single-line `grep` silently returns
empty against the wrapped form — caught here before stage 2. A package test
asserts `aleoFfiAbiVersion == AleoLib.expectedAbiVersion` and that both URLs
contain the release tag, so the triple-binding (plugin version ↔ tag ↔
`ffi_abi_version`) can't silently drift.

## Decision 4 — example lives in `packages/aleo_flutter/example`

Per spec §4 and Flutter plugin convention (not the repo's root `examples/`).
Because melos globs `packages/**`, both the plugin and its example become melos
packages, so each carries a test that passes **without** the native library
(manifest invariants; a widget smoke test that does not tap "run"). The on-device
load/API is the manual/stage-2 gate, not a `flutter test`.

## Stage 2 plan (next, after review)

1. Build the iOS slice(s) locally (`rust/build_ios.sh`); for a fast first
   dead-strip probe, a single `aarch64-apple-ios-sim` slice suffices.
2. `pod install` + run the example on an iOS simulator; `nm -gU` the final app
   binary to confirm the exports survived; iterate the `-force_load` path/flag
   until green.
3. `rust/build_android.sh`; run the example on an Android emulator.
4. Physical-device run for both (spec §9 hard gate), plus airplane-mode load to
   prove no runtime download.
5. A deliberately mismatched library → `IncompatibleNativeLibraryException`.

## Review fixes (round 2)

External review of the round-1 fixes; applied:

- **iOS local branch now validates** the xcframework (`Info.plist` present) before
  vendoring — symmetry with the Android per-ABI check; a truncated local build
  fails loudly instead of vendoring a broken framework.
- **iOS download is cached** by a `.provisioned-sha` stamp under `Frameworks/`, so
  repeated podspec-body evaluations during one `pod install` don't re-download
  35 MB. (Android already gets this from Gradle's task up-to-date check.)
- **Android namespace/group** `com.example.aleo_flutter` → `com.fxwallet.aleo_flutter`
  (avoids `com.example.*` R/BuildConfig collisions in the host app); the manifest
  `package=` attribute was dropped (AGP 8 derives it from `namespace`).
- **Android `compileSdk` 36 → 35** — the plugin floors every consumer's compileSdk
  and ships no compiled Android code, so it needn't be bleeding-edge.
- **Doc/comment honesty**: the Android local branch documents the partial-ABI
  tradeoff; the podspec notes `pod lib lint` only passes once an artifact can be
  provisioned.

Deliberately NOT changed:
- **perl dependency** in the manifest extractor — accepted (present on macOS + the
  GitHub runners; documented). Using `// dart format off` to avoid the wrap (and
  drop perl) was considered but risks cross-version formatter behavior.

## Review fixes (round 3 — from a real iOS build)

A reviewer ran an actual iOS build and hit the make-or-break items:

- **P1a — simulator link failed (`library 'aleo_rust' not found`).** `build_ios.sh`
  named the device slice `libaleo_rust.a` but the simulator fat archive
  `libaleo_rust-sim.a`, so the xcframework recorded a different library name per
  platform → a per-SDK linker flag (`-laleo_rust` vs `-laleo_rust-sim`). Fix: every
  slice now shares the basename `libaleo_rust.a` (the fat archive goes in its own
  `sim/` dir to avoid colliding with the device slice).
- **P1b — `-force_load` didn't reach the Runner.** It was in `pod_target_xcconfig`,
  which configures only the pod's own build and does not propagate to the app link,
  so the FFI exports were still stripped. Moved to `user_target_xcconfig` (the
  integrating target). The exact `${PODS_XCFRAMEWORKS_BUILD_DIR}` path + that this
  mechanism actually retains the symbols **still needs the `nm -gU` confirmation on
  the final Runner binary** (the real-build reviewer / stage 2).
- **P2 — Android download accepted a partial release.** The post-unzip check only
  required *one* ABI; it now requires all of `arm64-v8a armeabi-v7a x86_64` for the
  release (download) path. The local-build path stays lenient on purpose (see the
  L2 tradeoff above).

## Round 4 — iOS switched to a DYNAMIC framework (the live mechanism)

A fourth real-build failure (clean builds couldn't find the `-force_load`'d
`XCFrameworkIntermediates/.../libaleo_rust.a`, which CocoaPods only produces during
the build) made clear the static-lib + `-force_load` integration is inherently
fragile under CocoaPods/Xcode. Rather than keep patching it, **iOS now ships a
dynamic framework** (user decision), which removes the entire dead-strip class:

- `rust/build_ios.sh` builds the `cdylib` for each iOS target, sets the install
  name to `@rpath/AleoRust.framework/AleoRust`, wraps each slice in a flat
  `AleoRust.framework`, and `xcodebuild -create-xcframework`s a **dynamic**
  xcframework (device arm64 + simulator arm64/x86_64).
- The podspec just `vendored_frameworks` it. CocoaPods links + embeds + signs the
  dynamic framework; dyld loads it at app launch. No `-force_load`, no
  `pod_target`/`user_target` LDFLAGS hack, no build-intermediate path.
- `aleo_dart`'s `DyLib.getMobileDyLib()` iOS branch now `DynamicLibrary.open(
  'AleoRust.framework/AleoRust')` (was `process()`), so the framework is dlopened
  by name and loads regardless of any link-time dylib stripping. A dynamic
  library's exports are never dead-stripped, so the symbols are guaranteed present
  — only the load call needed nailing, not the symbols' existence.

Why this is strictly better: the static approach's failure mode was "the symbols
aren't in the binary"; the dynamic approach guarantees they are, reducing the
remaining risk to a load-path detail that is easy to verify (`nm -gU` on the
embedded `AleoRust.framework/AleoRust`, then the example's API call).

Stage-2 verification: built the dynamic xcframework, `pod install`ed the example,
clean-built for the iOS simulator, `nm -gU`'d the embedded framework, and ran
`mnemonicToAddress` — all pass on the simulator. Physical-device run still pending.

How `AleoFlutter.load()` resolves the framework: CocoaPods links + embeds it (the
keep-alive `Classes/` TU keeps the pod target building so it is linked), so dyld
loads it at launch. `DynamicLibrary.open('AleoRust.framework/AleoRust')` then
resolves to that already-loaded image by **suffix match** — a slash-bearing
relative path is NOT an rpath search. So the load depends on the framework being
auto-linked, which the podspec guarantees. **Device contingency:** if `.open()`
ever fails on a real device, `DynamicLibrary.process()` is the natural fallback
for an embedded dynamic library (it reads the already-loaded global symbol table).

## Review round 6 — iOS deployment target

The declared minimum was inconsistent: podspec/Info.plist said 13.0, but the
device slice's Mach-O `minos` was rustc's default (10) and the arm64 *simulator*
slice is intrinsically 14 (arm64 simulators don't exist below iOS 14). A binary
`minos` ≤ the declared minimum is the *safe* direction (it loads on the consumer's
OS), so nothing was broken — but three different numbers is sloppy.

Fixed by pinning everything to the fx-wallet app's deployment target (its
`ios/Podfile` is `platform :ios, '15.5'`, the plugin's only consumer):
`build_ios.sh` exports `IPHONEOS_DEPLOYMENT_TARGET=15.5` (`MIN_IOS`, also written
into each framework `Info.plist`), the podspec is `platform :ios, '15.5'`, and the
example `Podfile` is `15.5`. Verified: a **clean** device rebuild with the env
produces `LC_BUILD_VERSION minos 15.5` (Rust 1.96 honors `IPHONEOS_DEPLOYMENT_TARGET`).
Gotcha: changing only the env does NOT bust cargo's cache — a clean rebuild (or
`rm -rf target/<triple>/release`) is required to pick up a new deployment target.
The example sim integration test still passes at the 15.5 config.

(The local `rust/ios_lib` may carry older-minos cached slices; the shipped
artifact is a clean CI build, so it carries 15.5. Only the device slice ships;
simulator slices are stripped from the App Store archive.)

## Deferred to PR6b / later

- The release pipeline (`.github/workflows/release-aleo.yml`) that builds and
  uploads the assets on an `aleo_ffi-v*` tag, and pins the real SHA-256s.
- Generated `THIRD_PARTY_LICENSES` (`cargo about`).
- Public pub.dev publication and the `lib/aleo.dart`-vs-package-name warning.
