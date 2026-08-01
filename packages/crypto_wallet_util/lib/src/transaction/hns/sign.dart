import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'transaction.dart';

/// Sign hns message.
class FxHnsSign {
  final MTX mtx;
  final String mnemonic;

  FxHnsSign({required this.mtx, required this.mnemonic});

  String sign() {
    final tx = dynamicToUint8List(mtx.hex);

    // This parser assumes the input count, output count, output address
    // length, covenant item count, and each covenant item length are all
    // encoded as a single byte — true for ordinary transactions, but not a
    // valid assumption once any of those fields reaches 0xfd (253) and a
    // real CompactSize/varint encoding would switch to a multi-byte
    // prefix. Fail loudly here rather than silently reading the wrong
    // offset (and signing over the wrong bytes) once a value crosses that
    // boundary.
    const singleByteFieldLimit = 0xfd;
    if (mtx.inputs.length >= singleByteFieldLimit) {
      throw Exception(
          'HNS signing does not support ${mtx.inputs.length} inputs (varint input-count encoding unimplemented)');
    }
    if (mtx.outputs.length >= singleByteFieldLimit) {
      throw Exception(
          'HNS signing does not support ${mtx.outputs.length} outputs (varint output-count encoding unimplemented)');
    }

    // Version(4) + input count(1) + input count * (transaction hash(32) + output index(4) + sequence(4)) + output count(1)
    int index = 6 + mtx.inputs.length * 40;

    // Get outputs needed for signing
    final outputsHash = <int>[];
    for (var i = 0; i < mtx.outputs.length; i++) {
      var start = index;
      final addressLength = tx[start + 9];
      if (addressLength >= singleByteFieldLimit) {
        throw Exception(
            'HNS signing does not support an output address length of $addressLength (varint length encoding unimplemented)');
      }
      index += 11 + addressLength; // Output coin amount, output address length, output address, output protocol type
      var covenantCount = tx[index];
      if (covenantCount >= singleByteFieldLimit) {
        throw Exception(
            'HNS signing does not support $covenantCount covenant items (varint count encoding unimplemented)');
      }
      index += 1;
      for (var j = 0; j < covenantCount; j++) {
        final itemLength = tx[index];
        if (itemLength >= singleByteFieldLimit) {
          throw Exception(
              'HNS signing does not support a covenant item length of $itemLength (varint length encoding unimplemented)');
        }
        index += 1 + itemLength;
      }
      outputsHash.addAll(tx.sublist(start, index));
    }

    final outputsBlake2b =
        Blake2b.getBlake2bHash(Uint8List.fromList(outputsHash));

    index += 4;

    List<int> signs = [];

    Uint8List version = encodeInt(mtx.version, 4);
    Uint8List locktime = encodeInt(mtx.locktime, 4);

    List<int> prevOutHash = [];
    List<int> seq = [];
    for (var i = 0; i < mtx.inputs.length; i++) {
      var item = mtx.inputs[i];
      prevOutHash += dynamicToUint8List(item.prevout.hash) +
          encodeInt(item.prevout.index, 4);
      seq += encodeInt(item.sequence, 4);
    }
    Uint8List prevOutHashDigest =
        Blake2b.getBlake2bHash(Uint8List.fromList(prevOutHash));
    Uint8List seqDigest = Blake2b.getBlake2bHash(Uint8List.fromList(seq));

    final node = HDWallet.getBip32Node(mnemonic);
    for (var i = 0; i < mtx.inputs.length; i++) {
      final input = mtx.inputs[i];

      if (input.witness.first.isNotEmpty) {
        signs += [input.witness.length];
        for (var i = 0; i < input.witness.length; i++) {
          final item = dynamicToUint8List(input.witness[i]);
          signs += [item.length] + item;
        }
        continue;
      }

      String path = input.path.derivation;
      final child = node.derivePath(path);

      List<int> prevoutHash = dynamicToUint8List(input.prevout.hash) +
          encodeInt(input.prevout.index, 4);
      Uint8List sequence = encodeInt(input.sequence, 4);
      List<int> prevAddr = input.witness[1] == dynamicToString(child.publicKey)
          ? _prevEncode(Blake2b.getBlake2bHash(child.publicKey, size: 20))
          : dynamicToUint8List(input.witness[1]);
      List<int> prevLen = [prevAddr.length];
      Uint8List value = encodeInt(input.coin.value, 8);
      Uint8List type = encodeInt(1, 4);

      List<int> result = version +
          prevOutHashDigest +
          seqDigest +
          prevoutHash +
          prevLen +
          prevAddr +
          value +
          sequence +
          outputsBlake2b +
          locktime +
          type;

      Uint8List msg = Blake2b.getBlake2bHash(dynamicToUint8List(result));
      Uint8List sig = dynamicToUint8List(child.sign(msg) + [1]);
      List<int> witness = dynamicToUint8List(input.witness[1]);
      signs += [2, sig.length] + sig + [witness.length] + witness;
    }

    final finalHex = tx.sublist(0, index) + signs;
    return dynamicToString(finalHex);
  }

  String signAnyOne(int index) {
    final input = mtx.inputs[index];
    final output = mtx.outputs[mtx.outputs.length - 1 - index];
    final type = HnsHashType.ANYONE_CAN_PAY | HnsHashType.SINGLE_REVERSE;

    final child = HDWallet.getBip32Node(mnemonic);

    final prevoutHash = dynamicToUint8List(input.prevout.hash) +
        encodeInt(input.prevout.index, 4);
    final witnesses = input.witness;

    final prev = witnesses[1] == dynamicToString(child.publicKey)
        ? _prevEncode(Blake2b.getBlake2bHash(child.publicKey, size: 20))
        : dynamicToUint8List(witnesses[1]);

    final result = encodeInt(mtx.version, 4) +
        dynamicToUint8List(
            '0000000000000000000000000000000000000000000000000000000000000000') +
        dynamicToUint8List(
            '0000000000000000000000000000000000000000000000000000000000000000') +
        prevoutHash +
        [prev.length] +
        prev +
        encodeInt(input.coin.value, 8) +
        encodeInt(input.sequence, 4) +
        Blake2b.getBlake2bHash(dynamicToUint8List(output.encode)) +
        encodeInt(mtx.locktime, 4) +
        encodeInt(132, 4);

    final msg = Blake2b.getBlake2bHash(dynamicToUint8List(result));
    final sig = child.sign(msg) + [type];
    return dynamicToString(sig);
  }

  Uint8List _prevEncode(hash) {
    var raw = Uint8List(25);
    raw[0] = 0x76;
    raw[1] = 0xc0;
    raw[2] = 0x14;
    for (var i = 0; i < hash.length; i++) {
      raw[i + 3] = hash[i];
    }
    raw[23] = 0x88;
    raw[24] = 0xac;

    return raw;
  }
}
