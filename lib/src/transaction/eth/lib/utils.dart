import "package:crypto_wallet_util/src/utils/utils.dart";

/// Converts an [int] or [BigInt] to a [Uint8List]
Uint8List intToBuffer(i) {
  return Uint8List.fromList(i == null || i == 0 || i == BigInt.zero
      ? []
      : dynamicToUint8List(padToEven(intToHex(i).substring(2))));
}

/// Pads a [String] to have an even length
String padToEven(String value) {
  ArgumentError.checkNotNull(value);

  var a = value;
  if (a.length % 2 == 1) a = '0$a';

  return a;
}

/// Converts a [int] into a hex [String]
String intToHex(i) {
  ArgumentError.checkNotNull(i);

  return '0x${i.toRadixString(16)}';
}
