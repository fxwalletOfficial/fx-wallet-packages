#
# aleo_flutter (iOS): vendors the PREBUILT dynamic AleoRust.framework (as an
# xcframework) and links + embeds it. The native library is NOT compiled from
# source here — download_artifact.sh provides the xcframework (local build first,
# else the pinned GitHub Release verified against the in-package manifest); the
# only source (Classes/) is a tiny keep-alive TU so the pod target builds. The
# framework is loaded at runtime by AleoFlutter.load() via
# DynamicLibrary.open('AleoRust.framework/AleoRust').
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
Bundles the prebuilt dynamic AleoRust.framework and exposes the aleo_dart API. No
runtime download; the framework is embedded in the app and loaded at runtime via
DynamicLibrary.open('AleoRust.framework/AleoRust').
                       DESC
  s.homepage         = 'https://github.com/fxwalletOfficial/fx-wallet-packages'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FxWallet' => 'https://github.com/fxwalletOfficial' }
  s.source           = { :path => '.' }
  # A minimal source so the pod target actually builds; otherwise Xcode skips it
  # and its [CP] Copy XCFrameworks phase, and AleoRust.framework is never
  # extracted (link fails with "framework 'AleoRust' not found"). See Classes/.
  s.source_files = 'Classes/**/*'
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

  # AleoRust.xcframework ships a DYNAMIC framework (see rust/build_ios.sh).
  # CocoaPods links, embeds and signs it, so dyld loads it at app launch and its
  # exported FFI symbols stay intact — with NO dead-strip and NO -force_load.
  # AleoFlutter.load() reaches them via
  # DynamicLibrary.open('AleoRust.framework/AleoRust').
  #
  # This deliberately replaces the static-lib approach: a static linker drops the
  # unreferenced #[no_mangle] members, and the -force_load workaround had to point
  # at a CocoaPods build-time intermediate that does not exist yet on a clean
  # build. A dynamic framework is a self-contained binary whose exports are always
  # present — the whole dead-strip class disappears. (Spec §7.4.) Verify in stage 2:
  #   nm -gU "<App>.app/Frameworks/AleoRust.framework/AleoRust" | grep ffi_abi_version
  s.vendored_frameworks = 'Frameworks/AleoRust.xcframework'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
end
