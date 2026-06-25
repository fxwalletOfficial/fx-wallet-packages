import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;

ffi.Pointer<ffi.Uint8> dartListToC(Uint8List list) {
  final pointer = calloc<ffi.Uint8>(list.length);
  final arrayPtr = pointer.asTypedList(list.length);
  arrayPtr.setAll(0, list);
  return pointer;
}

ffi.Pointer<Utf8> dartStrToC(String string) {
  return string.toNativeUtf8();
}

String cStrToDart(ffi.Pointer<Utf8> charPointer) {
  return charPointer.toDartString();
}

typedef _FreeStringC = ffi.Void Function(ffi.Pointer<Utf8>);
typedef _FreeStringDart = void Function(ffi.Pointer<Utf8>);

/// Frees a string returned by the native library. Returned pointers are
/// allocated by Rust (`CString::into_raw`), so they must be released through
/// Rust's `free_string`, not the C allocator. If the loaded library predates
/// `free_string` (the older GPL build), this degrades to the previous
/// behaviour — the buffer is not freed — rather than throwing.
void freeNativeString(ffi.DynamicLibrary dyLib, ffi.Pointer<Utf8> ptr) {
  try {
    dyLib.lookupFunction<_FreeStringC, _FreeStringDart>('free_string')(ptr);
  } catch (_) {
    // Library has no free_string: fall back to leaking, as before.
  }
}

/// Copies a Rust-returned C string into a Dart string and frees the native
/// buffer (even when the conversion throws). Use for every `Pointer<Utf8>`
/// returned by the library.
String takeNativeString(ffi.DynamicLibrary dyLib, ffi.Pointer<Utf8> ptr) {
  try {
    return ptr.toDartString();
  } finally {
    freeNativeString(dyLib, ptr);
  }
}

/// Frees Dart-allocated input string pointers (from [dartStrToC]).
void freeAll(Iterable<ffi.Pointer<Utf8>> pointers) {
  for (final pointer in pointers) {
    malloc.free(pointer);
  }
}
