import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/transaction/sol/v2/crypto/buffer.dart';

extension hexList on List<int> {
  Uint8List toUint8List() => Uint8List.fromList(this);
  String toStr() => dynamicToString(this);
  String toHex() => dynamicToHex(this);
}

extension hexUint8List on Uint8List {
  String toStr() => dynamicToString(this);
  String toHex() => dynamicToHex(this);
}

extension hexString on String {
  String toStr() => dynamicToString(this);
  String toHex() => dynamicToString(this);
  Uint8List toUint8List() => dynamicToUint8List(this);
}

extension FxBigInt on BigInt {
  /// The minimum number of bytes required to store this big integer.
  int get byteLength => (bitLength + 7) >> 3;

  /// Converts this [BigInt] into a [Uint8List] of size [length].
  /// If [length] is omitted, the minimum number of bytes required to store this big integer value is used.
  Uint8List toUint8List([final int? length]) {
    final int byteLength = length ?? this.byteLength;
    assert(length == null || length >= byteLength,
        'The value $this overflows $byteLength byte(s)');
    return (Buffer(byteLength)..setBigInt(this, 0, byteLength)).asUint8List();
  }

  /// Creates a [BigInt] from an array of [bytes].
  static BigInt fromUint8List(final Iterable<int> bytes,
      [final Endian endian = Endian.little]) {
    return Buffer.fromList(bytes).getBigUint(0, bytes.length, endian);
  }
}
