#
# aleo_flutter (iOS): vendors the PREBUILT static AleoRust.xcframework and links
# it into the app. Unlike the flutter_create plugin_ffi template there is no C
# source compiled here — download_artifact.sh provides the xcframework (local
# build first, else the pinned GitHub Release verified against the in-package
# manifest), and the static symbols are reached at runtime via
# DynamicLibrary.process() (see aleo_dart's DyLib.getMobileDyLib).
#
# `pod lib lint` only passes once an artifact can be provisioned (a local
# build or a pinned release): the body fetch below runs during evaluation, so
# linting with neither available fails by design (expected in stage 1).
#
Pod::Spec.new do |s|
  s.name             = 'aleo_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Prebuilt aleo_rust native library for Flutter (iOS).'
  s.description      = <<-DESC
Bundles the static AleoRust.xcframework and exposes the aleo_dart API. No runtime
download; the symbols are statically linked into the app and loaded via
DynamicLibrary.process().
                       DESC
  s.homepage         = 'https://github.com/fxwalletOfficial/fx-wallet-packages'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FxWallet' => 'https://github.com/fxwalletOfficial' }
  s.source           = { :path => '.' }
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  # Provide ios/Frameworks/AleoRust.xcframework before CocoaPods globs
  # vendored_frameworks below. CocoaPods runs `prepare_command` only for pods it
  # DOWNLOADS; Flutter integrates plugins as :path (development) pods, referenced
  # in place and never downloaded, so prepare_command would NOT run. The podspec
  # body, by contrast, is evaluated on every `pod install` for every pod (path
  # included) — so fetch here. download_artifact.sh is idempotent.
  system('bash', "#{__dir__}/download_artifact.sh") or
    raise 'aleo_flutter: failed to provision AleoRust.xcframework (see download_artifact.sh output)'
  s.vendored_frameworks = 'Frameworks/AleoRust.xcframework'

  # DEAD-STRIP RETENTION — PR6 spec §7.4, the make-or-break detail.
  #
  # AleoRust.xcframework is a STATIC archive. A static linker only pulls archive
  # members whose symbols are referenced; nothing in the app references the
  # #[no_mangle] exports directly (they are resolved at runtime via
  # DynamicLibrary.process()), so without intervention the members are never
  # pulled in and process() finds nothing. -force_load pulls EVERY object file
  # from the archive, so all exports survive into the app binary.
  #
  # NOTE 1: DEAD_CODE_STRIPPING=NO alone is INSUFFICIENT — it prevents stripping
  # AFTER member selection, but unreferenced archive members are never selected.
  #
  # NOTE 2: -force_load must land on the FINAL app (Runner) link, so it belongs in
  # user_target_xcconfig (the integrating target), NOT pod_target_xcconfig — the
  # latter only affects the pod's own build and does NOT propagate to the app, so
  # the exports were still stripped (review P1).
  #
  # The path resolves to the per-SDK slice CocoaPods extracts; every slice shares
  # the basename libaleo_rust.a (see rust/build_ios.sh, fixed in lockstep). VERIFY
  # in stage 2 on the final app binary:
  #   nm -gU "$BUILT_PRODUCTS_DIR/Runner.app/Runner" | grep -E 'ffi_abi_version|execute_proof_checked'
  # Both must be present; if not, adjust this path/mechanism.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '-force_load "${PODS_XCFRAMEWORKS_BUILD_DIR}/aleo_flutter/libaleo_rust.a"',
  }
end
