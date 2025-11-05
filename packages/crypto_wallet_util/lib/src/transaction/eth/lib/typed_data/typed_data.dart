import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

import './constants.dart';
import './util.dart';
import '../utils.dart';

/// Sign typed data, support all versions
///
/// @param {String|Uint8List} private key - wallet's private key
/// @param {String} jsonData - raw json of typed data
/// @param {TypedDataVersion} version - typed data sign method version
/// @returns {String} - signature
///
String signTypedData(
    {required Uint8List privateKey,
    required String jsonData,
    required TypedDataVersion version}) {
  final message =
      TypedDataUtil.hashMessage(jsonData: jsonData, version: version);
  final signature = EcdaSignature.signForEth(message, privateKey);

  return concatSig(signature.r, signature.s, intToBuffer(signature.v));
}

/// Sign typed data compact, support all versions
String signTypedDataCompact(
    {required Uint8List privateKey,
    required String jsonData,
    required TypedDataVersion version}) {
  final message =
      TypedDataUtil.hashMessage(jsonData: jsonData, version: version);

  return signToCompact(message: message, privateKey: privateKey);
}

String concatSig(Uint8List r, Uint8List s, Uint8List v) {
  var rSig = fromSigned(r);
  var sSig = fromSigned(s);
  var vSig = bufferToInt(v);
  var rStr = _padWithZeroes(dynamicToString(toUnsigned(rSig)), 64);
  var sStr = _padWithZeroes(dynamicToString(toUnsigned(sSig)), 64);
  var vStr = dynamicToString(intToHex(vSig));
  return dynamicToHex(rStr + sStr + vStr);
}

String concatSigCompact(Uint8List r, Uint8List s) {
  var rSig = fromSigned(r);
  var sSig = fromSigned(s);
  var rStr = _padWithZeroes(dynamicToString(toUnsigned(rSig)), 64);
  var sStr = _padWithZeroes(dynamicToString(toUnsigned(sSig)), 64);
  return dynamicToHex(rStr + sStr);
}

String _padWithZeroes(String number, int length) {
  var myString = number;
  while (myString.length < length) {
    myString = '0$myString';
  }
  return myString;
}

String signToCompact(
    {required Uint8List message, required Uint8List privateKey}) {
  final sig = EcdaSignature.signForEth(message, privateKey);
  final recoveryParam = 1 - sig.v % 2;

  final s = sig.s;
  if (recoveryParam > 0) s[0] |= 0x80;

  return concatSigCompact((sig.r), s);
}

/// Returns the keccak-256 hash of `message`, prefixed with the header used by the `eth_sign` RPC call. The output of this function
/// can be fed into `ecsign` to produce the same signature as the `eth_sign` call for a given `message`, or fed to `ecrecover` along
/// with a signature to recover the public key used to produce the signature.
Uint8List hashPersonalMessage(dynamic message) {
  var prefix = toBuffer("\u0019Ethereum Signed Message:\n${message.length.toString()}");
  var bytesBuffer = BytesBuffer();
  bytesBuffer.add(prefix);
  bytesBuffer.add(message);
  return keccak(bytesBuffer.toBytes());
}
