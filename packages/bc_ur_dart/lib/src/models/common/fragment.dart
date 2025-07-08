import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/common/seq.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/byte_words.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';
import 'package:xrandom/xrandom.dart';

/// Fragment of UR.
class FragmentUR extends UR {
  final int messageLength;
  final int checksum;
  final Uint8List part;

  List<int> _indexes = [];
  List<int> get indexes => _indexes;
  bool get isSimple => _indexes.length == 1;

  FragmentUR({required super.type, required URSeq seq, required this.messageLength, required this.checksum, required this.part}) : super.fromCBOR(
    seq: seq,
    value: CborList([
      CborSmallInt(seq.num),
      CborSmallInt(seq.length),
      CborSmallInt(messageLength),
      CborSmallInt(checksum),
      CborBytes(part)
    ])
  ) {
    setIndexes();
  }

  /// Generate fragment from simple UR. Only UR with valid seq can be generate.
  static FragmentUR fromUR({required UR ur}) {
    final data = ur.decodeCBOR();
    if (data is! CborList || data.length != 5) throw Exception('Invalid fragment ur');

    final seqNum = (data[0] as CborInt).toInt();
    final seqLength = (data[1] as CborInt).toInt();
    final messageLength = (data[2] as CborInt).toInt();
    final checksum = (data[3] as CborInt).toInt();
    final part = Uint8List.fromList((data[4] as CborBytes).bytes);

    final item = FragmentUR(
      seq: URSeq(num: seqNum, length: seqLength),
      messageLength: messageLength,
      checksum: checksum,
      part: part,
      type: ur.type
    );

    item.setIndexes();
    return item;
  }

  /// Generate fragment indexes for packet final UR.
  void setIndexes({List<int>? value}) {
    if (value != null) {
      _indexes = value;
      return;
    }

    if (seq.num <= seq.length) {
      _indexes = [seq.num -1];
      return;
    }

    final seed = intToByte(seq.num, 4) + intToByte(checksum, 4);
    final digest = sha256(seed);

    final rng = Xoshiro256ss(
      int.parse('0x${hex.encode(digest.sublist(0, 8))}'),
      int.parse('0x${hex.encode(digest.sublist(8, 16))}'),
      int.parse('0x${hex.encode(digest.sublist(16, 24))}'),
      int.parse('0x${hex.encode(digest.sublist(24, 32))}'),
    );

    final degreeProbabilities = List.generate(seq.length, (i) => 1 / (i + 1));
    final indexedOutcomes = List.generate(seq.length, (i) => i);
    final sum = degreeProbabilities.reduce((acc, val) => acc + val);
    final scaledProbabilities = degreeProbabilities.map((prob) => (prob * seq.length) / sum).toList();

    final prob = List.filled(seq.length, 0.0);
    final alias = List.filled(seq.length, 0);

    final small = [];
    final large = [];
    for (var i = seq.length - 1; i >= 0; i--) {
      scaledProbabilities[i] < 1 ? small.add(i) : large.add(i);
    }

    while (small.isNotEmpty && large.isNotEmpty) {
      var less = small.removeLast();
      var more = large.removeLast();
      prob[less] = scaledProbabilities[less];
      alias[less] = more;
      scaledProbabilities[more] = (scaledProbabilities[more] + scaledProbabilities[less]) - 1;
      scaledProbabilities[more] < 1 ? small.add(more) : large.add(more);
    }

    while (large.isNotEmpty) {
      prob[large.removeLast()] = 1;
    }

    while (small.isNotEmpty) {
      prob[small.removeLast()] = 1;
    }

    var c = (rng.nextDouble() * prob.length).floor();
    final samples = indexedOutcomes[(rng.nextDouble() < prob[c]) ? c : alias[c]];
    final degree = samples + 1;

    final remaining = List.generate(seq.length, (i) => i);

    final result = <int>[];
    while (remaining.isNotEmpty) {
      final index = (rng.nextDouble() * remaining.length).floor();
      final item = remaining[index];
      remaining.removeAt(index);
      result.add(item);
    }

    _indexes = result.sublist(0, degree);
  }

  @override
  String encode() => 'ur:$type/${seq.toString()}/${ByteWords.encode(payload)}'.toUpperCase();
}
