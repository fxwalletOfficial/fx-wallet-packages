import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/bip32/src/bip32_base.dart' show NetworkType;

import '../crypto.dart';
import '../models/networks.dart';
import '../utils/varuint.dart';

Uint8List magicHash(String message, [NetworkType? network]) {
  network = network ?? bitcoin;
  Uint8List messagePrefix = Uint8List.fromList(utf8.encode(network.messagePrefix));
  int messageVISize = encodingLength(message.length);
  int length = messagePrefix.length + messageVISize + message.length;
  Uint8List buffer = Uint8List(length);
  buffer.setRange(0, messagePrefix.length, messagePrefix);
  encode(message.length, buffer, messagePrefix.length);
  buffer.setRange(messagePrefix.length + messageVISize, length, utf8.encode(message));

  return hash256(buffer);
}
