import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Regression tests for F10: the PSBT DER→raw conversion used to copy `r`
/// and `s` byte-for-byte (stripping at most one leading 0x00) without
/// padding either back to 32 bytes. Whenever `r` was legitimately shorter
/// than 32 bytes, the concatenated `r||s` came out shorter than 64 bytes
/// and `s` no longer started at byte offset 32.
void main() {
  Uint8List buildDer(Uint8List r, Uint8List s, {int? trailingByte}) {
    final body = <int>[
      0x02, r.length, ...r,
      0x02, s.length, ...s,
    ];
    final der = <int>[0x30, body.length, ...body];
    if (trailingByte != null) der.add(trailingByte);
    return Uint8List.fromList(der);
  }

  test('pads a 31-byte r without shifting s to the wrong offset', () {
    // r has no leading zero byte in its DER encoding (top bit already 0),
    // so DER legitimately stores it in 31 bytes.
    final r = Uint8List.fromList(List.generate(31, (_) => 0x11));
    // s needs a DER sign-disambiguation 0x00 (top bit of 0xff is set),
    // making its DER encoding 33 bytes.
    final s = Uint8List.fromList([0x00, ...List.generate(32, (_) => 0xff)]);
    final der = buildDer(r, s, trailingByte: 0x01);

    final raw = EcdaSignature.derToRaw(der);

    expect(raw.length, 64);
    // r is right-aligned within the first 32 bytes: one 0x00 pad byte,
    // then the 31 0x11 bytes.
    expect(raw[0], 0x00);
    expect(raw.sublist(1, 32), List.filled(31, 0x11));
    // s starts at exactly offset 32 (the DER sign byte is dropped since
    // it's not part of the 32-byte value).
    expect(raw.sublist(32, 64), List.filled(32, 0xff));
  });

  test('round-trips a full 32/32-byte r and s unchanged', () {
    final r = Uint8List.fromList(List.generate(32, (i) => i + 1));
    final s = Uint8List.fromList(List.generate(32, (i) => 32 - i));
    final der = buildDer(r, s);

    final raw = EcdaSignature.derToRaw(der);
    expect(raw.length, 64);
    expect(raw.sublist(0, 32), r);
    expect(raw.sublist(32, 64), s);
  });

  test('throws on truncated DER instead of misreading adjacent bytes', () {
    final der = Uint8List.fromList([0x30, 0x44, 0x02, 0x20]); // claims more than it has
    expect(() => EcdaSignature.derToRaw(der), throwsFormatException);
  });

  test('rejects an excessively padded positive integer', () {
    final r = Uint8List.fromList([0x00, ...List.filled(32, 0x11)]);
    final s = Uint8List.fromList(List.filled(32, 0x22));
    final der = buildDer(r, s, trailingByte: 0x01);

    expect(() => EcdaSignature.derToRaw(der), throwsFormatException);
  });

  test('rejects a negative DER integer with no sign-disambiguation byte', () {
    final r = Uint8List.fromList([0x80, ...List.filled(31, 0x11)]);
    final s = Uint8List.fromList(List.filled(32, 0x22));
    final der = buildDer(r, s, trailingByte: 0x01);

    expect(() => EcdaSignature.derToRaw(der), throwsFormatException);
  });

  test('rejects a 33-byte integer without a sign-disambiguation zero', () {
    final r = Uint8List.fromList([0x01, ...List.filled(32, 0x80)]);
    final s = Uint8List.fromList(List.filled(32, 0x22));
    final der = buildDer(r, s, trailingByte: 0x01);

    expect(() => EcdaSignature.derToRaw(der), throwsFormatException);
  });

  test('rejects more than one byte after the DER payload', () {
    final r = Uint8List.fromList(List.filled(32, 0x11));
    final s = Uint8List.fromList(List.filled(32, 0x22));
    final der = Uint8List.fromList([
      ...buildDer(r, s, trailingByte: 0x01),
      0x02,
    ]);

    expect(() => EcdaSignature.derToRaw(der), throwsFormatException);
  });
}
