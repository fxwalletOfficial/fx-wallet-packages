import 'dart:math';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';

import 'package:bc_ur_dart/src/models/common/fragment.dart';
import 'package:bc_ur_dart/src/utils/byte_words.dart';
import 'package:bc_ur_dart/src/utils/crc32.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:bc_ur_dart/src/models/common/seq.dart';
import 'package:bc_ur_dart/src/utils/type.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';

class UR {
  String _type = '';
  String get type => _type;

  Uint8List _payload = Uint8List(0);
  Uint8List get payload => _payload;

  final URSeq _seq = URSeq(length: 0, num: 0);
  URSeq get seq => _seq;

  bool get isComplete => payload.isNotEmpty;
  bool get isFragment => seq.isFragment;
  bool get isSingle => _fragments.length <= 1;

  /// Expected message length. Used for fragment UR.
  int _expectedMessageLength = 0;

  /// Expected checksum for complete UR.
  int _expectedChecksum = 0;

  /// Expected fragment payload length.
  int _expectedFragmentLength = 0;

  /// Min fragment length for getting UR by [next].
  int minLength;

  /// Max fragment length for getting UR by [next].
  int maxLength;

  /// Sequence number for fragment UR. When getting by [next], it will +1.
  int _seqNum = 0;

  /// Expected fragment indexes. It will be generate when start [read] fragment UR.
  final List<int> _expectedPartIndexes = [];
  List<int> get expectedPartIndexes => _expectedPartIndexes;

  /// Received fragment indexes.
  final List<int> _receivedPartIndexes = [];
  List<int> get receivedPartIndexes => _receivedPartIndexes;

  /// Mixed fragments.
  final List<FragmentUR> _mixedParts = [];

  /// Queued fragments to handle.
  final List<FragmentUR> _queuedParts = [];

  /// Simple fragments.
  final List<FragmentUR> _simpleParts = [];

  /// fragments to complete UR.
  final List<Uint8List> _fragments = [];

  UR({String type = '', Uint8List? payload, URSeq? seq, this.minLength = 10, this.maxLength = 100}) {
    _type = type;
    _payload = payload ?? Uint8List(0);
    _seq.copy(seq);
  }

  /// Generate UR by string [value] in the format of ur:type/length-num/data.
  factory UR.decode(String value) {
    final components = value.getURMatch();
    if (components == null) throw InvalidFormatURException(input: value);

    final type = components.group(1)!;
    final seq = URSeq.decode(components.group(3) ?? '');
    final payload = ByteWords.decode(components.group(4)!);

    return UR(type: type, payload: payload, seq: seq);
  }

  /// Generate UR by CBOR object.
  UR.fromCBOR({required String type, required CborValue value, URSeq? seq, this.minLength = 10, this.maxLength = 100}) {
    _type = type;
    _payload = Uint8List.fromList(cbor.encode(value));
    if (seq != null) _seq.copy(seq);
  }

  /// Encode payload to show UR string.
  String encode() => 'ur:$type/${ByteWords.encode(payload)}'.toUpperCase();

  /// Decode payload to [CborValue] object.
  CborValue decodeCBOR() => cbor.decode(payload);

  /// Read UR string. If is single UR, return. If is fragment, can continue read next fragment until read all necessary parts.
  bool read(String value) {
    if (isComplete) return false;

    final ur = UR.decode(value);
    // It is only a single body, just get data and return.
    if (!ur.isFragment) {
      _type = ur.type;
      _payload = ur.payload;
      return true;
    }

    final fragment = FragmentUR.fromUR(ur: ur);
    if (!_check(fragment) || !(fragment.seq == ur.seq)) return false;

    _queuedParts.add(fragment);
    while (!isComplete && _queuedParts.isNotEmpty) {
      _processQueuedItem();
    }

    return isComplete;
  }

  /// Check expected target when read fragment UR. Set data when read first and compare others.
  bool _check(FragmentUR ur) {
    if (_type.isNotEmpty) {
      return _type == ur.type &&
        seq.length == ur.seq.length &&
        _expectedMessageLength == ur.messageLength &&
        _expectedChecksum == ur.checksum &&
        _expectedFragmentLength == ur.part.length;
    }

    _type = ur.type;
    seq.length = ur.seq.length;
    _expectedMessageLength = ur.messageLength;
    _expectedChecksum = ur.checksum;
    _expectedFragmentLength = ur.part.length;

    if (seq.length > 0) {
      _expectedPartIndexes.clear();
      _expectedPartIndexes.addAll(List.generate(ur.seq.length, (i) => i));
    }

    return true;
  }

  /// Process queued fragments.
  void _processQueuedItem() {
    if (_queuedParts.isEmpty) return;
    final part = _queuedParts.removeAt(0);

    part.isSimple ? _processSimplePart(part) : _processMixedPart(part);
  }

  /// Process simple fragment.
  void _processSimplePart(FragmentUR fragment) {
    // Don't process duplicate parts
    final fragmentIndex = fragment.indexes.first;
    if (_receivedPartIndexes.contains(fragmentIndex)) return;

    _simpleParts.add(fragment);
    _receivedPartIndexes.add(fragmentIndex);

    // If we've received all the parts
    if (arraysEqual(_receivedPartIndexes, _expectedPartIndexes)) {
      // Reassemble the message from its fragments
      _simpleParts.sort((a, b) => (a.indexes[0] - b.indexes[0]));
      _payload = _simpleParts.map((e) => e.part).reduce((a, b) => Uint8List.fromList(a + b)).sublist(0, _expectedMessageLength);
    } else {
      _reduceMixedBy(fragment);
    }
  }

  /// Process mixed fragment.
  void _processMixedPart(FragmentUR fragment) {
    if (_mixedParts.any((e) => arraysEqual(e.indexes, fragment.indexes))) return;
    final simple = [fragment, ..._simpleParts].reduce((a, b) => _reducePartByPart(a, b));

    final part = [simple, ..._mixedParts].reduce((a, b) => _reducePartByPart(a, b));

    if (part.isSimple) {
      _queuedParts.add(part);
    } else {
      _reduceMixedBy(part);
      _mixedParts.add(part);
    }
  }

  /// Reduce mixed fragment.
  void _reduceMixedBy(FragmentUR fragment) {
    final newMixed = <FragmentUR>[];

    for (final item in _mixedParts) {
      final ur = _reducePartByPart(item, fragment);
      ur.isSimple ? _queuedParts.add(item) : newMixed.add(ur);
    }

    _mixedParts.clear();
    _mixedParts.addAll(newMixed);
  }

  FragmentUR _reducePartByPart(FragmentUR a, FragmentUR b) {
    if (!b.indexes.every((e) => a.indexes.contains(e))) return a;

    final newIndexes = a.indexes.where((e) => !b.indexes.contains(e)).toList();
    final newLength = max(a.part.length, b.part.length);
    final newPart = Uint8List(newLength);

    for (var i = 0; i < newLength; i++) {
      newPart[i] = a.part[i] ^ b.part[i];
    }

    final item = FragmentUR(
      type: a.type,
      seq: URSeq(num: a.seq.num, length: a.seq.length),
      messageLength: _expectedMessageLength,
      checksum: a.crc,
      part: newPart
    );
    item.setIndexes(value: newIndexes);
    return item;
  }

  int _crc = -1;
  int get crc {
    if (_crc < 0) _crc = CRC32.compute(payload);
    return _crc;
  }

  /// Get next UR. If payload is shorter than [maxLength], it will return the same value of [encode]. If not, it will return fragment.
  /// Be ensure to return enough fragments to complete full data.
  String next() {
    if (_fragments.isEmpty) _partition();
    if (_fragments.length <= 1) return encode();

    _seqNum++;
    final item = FragmentUR(
      type: type,
      seq: URSeq(num: _seqNum, length: _fragments.length),
      messageLength: payload.length,
      checksum: crc,
      part: Uint8List(0)
    );
    item.setIndexes();

    final indexes = List<int>.from(item.indexes);
    final mixed = _mix(indexes);

    final fragment = FragmentUR(
      type: type,
      seq: URSeq(num: _seqNum, length: _fragments.length),
      messageLength: payload.length,
      checksum: crc,
      part: mixed
    );
    fragment.setIndexes(value: indexes);

    return fragment.encode();
  }

  /// Split data to fragment.
  void _partition() {
    final length = _getFragmentLength();
    List<int> remaining = List.from(payload);
    final items = <Uint8List>[];

    while (remaining.isNotEmpty) {
      final len = length > remaining.length ? remaining.length : length;
      List<int> item = remaining.sublist(0, len);
      remaining = remaining.sublist(len);

      if (item.length < length) item = item + List.filled(length - item.length, 0);
      items.add(Uint8List.fromList(item));
    }

    _fragments.clear();
    _fragments.addAll(items);
  }

  /// Calculate suitable fragment length.
  int _getFragmentLength() {
    if (maxLength < minLength || maxLength <= 0 || minLength <= 0) throw Exception(URExceptionType.invalidParams.toString());

    final maxCount = (payload.length / minLength).ceil();
    int length = 0;

    for (var count = 1; count <= maxCount; count++) {
      length = (payload.length / count).ceil();
      if (length <= maxLength) break;
    }

    return length;
  }

  Uint8List _mix(List<int> value) {
    List<int> result = List.filled(_fragments.first.length, 0);
    for (var i = 0; i < value.length; i++) {
      result = bufferXOR(_fragments[value[i]], result);
    }

    return Uint8List.fromList(result);
  }

  /// Generate random UUID for request.
  static Uint8List generateUUid() => generateUuid();
}
