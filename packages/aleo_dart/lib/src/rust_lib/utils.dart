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
