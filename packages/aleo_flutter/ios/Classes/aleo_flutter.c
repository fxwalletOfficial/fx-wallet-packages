// Minimal translation unit so the aleo_flutter CocoaPods target has a source to
// compile. Without any source, Xcode treats the target as nothing-to-build and
// skips its build phases — including [CP] Copy XCFrameworks, which extracts the
// vendored dynamic AleoRust.framework. The app then fails to link with
// "framework 'AleoRust' not found".
//
// The real FFI symbols live in the bundled dynamic AleoRust.framework (built by
// rust/build_ios.sh, loaded at runtime via DynamicLibrary). This file
// intentionally provides nothing else.
void _aleo_flutter_pod_keepalive(void) {}
