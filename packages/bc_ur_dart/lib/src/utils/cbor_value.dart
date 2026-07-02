import 'dart:typed_data';

import 'package:cbor/cbor.dart';

Uint8List? cborBytesOrNull(CborValue? value, {int? length}) {
  if (value is! CborBytes) return null;
  final bytes = Uint8List.fromList(value.bytes);
  if (length != null && bytes.length != length) return null;
  return bytes;
}

int? cborIntOrNull(CborValue? value, {int? min, int? max}) {
  if (value is! CborInt) return null;
  final number = value.toBigInt();
  if (min != null && number < BigInt.from(min)) return null;
  if (max != null && number > BigInt.from(max)) return null;
  return number.toInt();
}

BigInt? cborBigIntOrNull(CborValue? value, {BigInt? min, BigInt? max}) {
  if (value is! CborInt) return null;
  final number = value.toBigInt();
  if (min != null && number < min) return null;
  if (max != null && number > max) return null;
  return number;
}

String? cborTextOrNull(CborValue? value) {
  return value is CborString ? value.toString() : null;
}

CborMap? cborMapOrNull(CborValue? value) {
  return value is CborMap ? value : null;
}

CborList? cborListOrNull(CborValue? value) {
  return value is CborList ? value : null;
}

bool? cborBoolOrNull(CborValue? value) {
  return value is CborBool ? value.value : null;
}
