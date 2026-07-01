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
    _setPayload(payload ?? Uint8List(0));
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
    _setPayload(Uint8List.fromList(cbor.encode(value)));
    if (seq != null) _seq.copy(seq);
  }

  /// Encode payload to show UR string.
  String encode() => 'ur:$type/${ByteWords.encode(payload)}'.toUpperCase();

  /// Decode payload to [CborValue] object.
  CborValue decodeCBOR() => cbor.decode(payload);

  /// Read UR string. If is single UR, return. If is fragment, can continue read next fragment until read all necessary parts.
  bool read(String value) {
    if (isComplete) return false;

    late final UR ur;
    try {
      ur = UR.decode(value);
    } on URException {
      return false;
    }

    // It is only a single body, just get data and return.
    if (!ur.isFragment) {
      if (_type.isNotEmpty) return false;
      _type = ur.type;
      _setPayload(ur.payload);
      return true;
    }

    late final FragmentUR fragment;
    try {
      fragment = FragmentUR.fromUR(ur: ur);
    } on URException {
      return false;
    }
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
      return _type == ur.type && seq.length == ur.seq.length && _expectedMessageLength == ur.messageLength && _expectedChecksum == ur.checksum && _expectedFragmentLength == ur.part.length;
    }

    _type = ur.type;
    seq.length = ur.seq.length;
    _expectedMessageLength = ur.messageLength;
    _expectedChecksum = ur.checksum;
    _expectedFragmentLength = ur.part.length;

    _expectedPartIndexes.clear();
    _expectedPartIndexes.addAll(List.generate(ur.seq.length, (i) => i));

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
      final builder = BytesBuilder(copy: false);
      for (final part in _simpleParts) {
        builder.add(part.part);
      }
      final payload = builder.takeBytes().sublist(0, _expectedMessageLength);
      if (CRC32.compute(payload) != _expectedChecksum) {
        _resetReadState();
        return;
      }
      _setPayload(payload);
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
      ur.isSimple ? _queuedParts.add(ur) : newMixed.add(ur);
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

    final item = FragmentUR(type: a.type, seq: URSeq(num: a.seq.num, length: a.seq.length), messageLength: a.messageLength, checksum: a.checksum, part: newPart);
    item.setIndexes(value: newIndexes);
    return item;
  }

  int _crc = -1;
  int get crc {
    if (_crc < 0) _crc = CRC32.compute(payload);
    return _crc;
  }

  void _setPayload(Uint8List value) {
    _payload = value;
    _crc = -1;
  }

  void _resetReadState() {
    _type = '';
    _setPayload(Uint8List(0));
    seq.num = 0;
    seq.length = 0;
    _expectedMessageLength = 0;
    _expectedChecksum = 0;
    _expectedFragmentLength = 0;
    _expectedPartIndexes.clear();
    _receivedPartIndexes.clear();
    _mixedParts.clear();
    _queuedParts.clear();
    _simpleParts.clear();
  }

  void reset() {
    _resetReadState();
  }

  /// Get next UR. If payload is shorter than [maxLength], it will return the same value of [encode]. If not, it will return fragment.
  /// Be ensure to return enough fragments to complete full data.
  String next() {
    if (_fragments.isEmpty) _partition();
    if (_fragments.length <= 1) return encode();

    _seqNum = (_seqNum % FragmentUR.maxUint32) + 1;
    final item = FragmentUR(type: type, seq: URSeq(num: _seqNum, length: _fragments.length), messageLength: payload.length, checksum: crc, part: Uint8List(0));
    item.setIndexes();

    final indexes = List<int>.from(item.indexes);
    final mixed = _mix(indexes);

    final fragment = FragmentUR(type: type, seq: URSeq(num: _seqNum, length: _fragments.length), messageLength: payload.length, checksum: crc, part: mixed);
    fragment.setIndexes(value: indexes);

    return fragment.encode();
  }

  /// Split data to fragment.
  void _partition() {
    final length = _getFragmentLength();
    final items = <Uint8List>[];

    for (var offset = 0; offset < payload.length; offset += length) {
      final end = min(offset + length, payload.length);
      final item = Uint8List(length);
      item.setRange(0, end - offset, payload, offset);
      items.add(item);
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
