import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';

enum ScSignRequestKeys {
  zero,
  uuid,
  xfp,
  path,
  address,
  publicKey,
  signingPayloadData,
  fee,
  outputs,
  origin,
  chain,
  // Appended at the end to keep existing CBOR key indices stable / backward compatible.
  crossChainFee,
  signingPayloadEncoding,
}

/// SC signing payload 的线格式。
///
/// [json] 是 0.1.27 及更早版本使用的原始 JSON bytes；[zlibJsonV1] 使用 Dart SDK
/// zlib level 6 压缩同一份 JSON bytes。冷端解压后仍从完整交易重建并计算签名摘要。
enum ScSigningPayloadEncoding {
  json,
  zlibJsonV1,
}

class ScSignRequest extends RegistryItem {
  static const int _zlibJsonV1WireValue = 1;

  /// 解压后的 signing payload 上限。
  ///
  /// 4 MiB 可覆盖当前 1000-input 压力 fixture，同时限制恶意压缩载荷的内存放大。
  static const int maxSigningPayloadBytes = 4 * 1024 * 1024;

  /// Request id follows the same UUID-bytes convention as other sign requests.
  /// It is generated lazily when omitted by the caller.
  Uint8List? uuid;
  final String xfp;
  final String path;
  final String address;
  final String publicKey;

  /// The value of API response `signing_payload.data`.
  /// Cold side passes this directly to `ScUnsignedTransaction.fromJson`.
  final Map<String, dynamic> signingPayloadData;

  /// [signingPayloadData] 在 UR 中使用的编码。
  final ScSigningPayloadEncoding signingPayloadEncoding;

  /// Optional display metadata from the hot side; not used to build the SC tx.
  final String? fee;
  final List<dynamic>? outputs;
  final String? origin;
  final String chain;

  /// Bridge platform service fee (display units, e.g. `0.3`). Display metadata
  /// only; the cold side must still verify it against the signed `siacoinOutputs`.
  final String? crossChainFee;

  ScSignRequest({
    this.uuid,
    required this.xfp,
    required this.path,
    required this.address,
    required this.publicKey,
    required this.signingPayloadData,
    this.signingPayloadEncoding = ScSigningPayloadEncoding.json,
    this.fee,
    this.outputs,
    this.origin,
    this.chain = '',
    this.crossChainFee,
  });

  Uint8List getRequestId() => uuid ??= generateUuid();
  String getRequestIdString() => uuidStringify(getRequestId());

  @override
  RegistryType getRegistryType() => RegistryType.SC_SIGN_REQUEST;

  @override
  CborValue toCborValue() {
    final signingPayloadBytes = RegistryItem.jsonBytes(signingPayloadData);
    final Map<CborValue, CborValue> map = {
      CborSmallInt(ScSignRequestKeys.uuid.index): cborBytes(
        getRequestId(),
        tags: [RegistryType.UUID.tag],
      ),
      CborSmallInt(ScSignRequestKeys.xfp.index): CborString(xfp),
      CborSmallInt(ScSignRequestKeys.path.index): CborString(path),
      CborSmallInt(ScSignRequestKeys.address.index): CborString(address),
      CborSmallInt(ScSignRequestKeys.publicKey.index): CborString(publicKey),
      CborSmallInt(ScSignRequestKeys.signingPayloadData.index): cborBytes(_encodeSigningPayload(signingPayloadBytes)),
    };

    // Legacy JSON 不写 marker，保证默认构造的请求与 0.1.27 逐字节兼容。
    if (signingPayloadEncoding == ScSigningPayloadEncoding.zlibJsonV1) {
      map[CborSmallInt(ScSignRequestKeys.signingPayloadEncoding.index)] = CborSmallInt(_zlibJsonV1WireValue);
    }

    if (origin != null) {
      map[CborSmallInt(ScSignRequestKeys.origin.index)] = CborString(origin!);
    }
    if (fee != null) {
      map[CborSmallInt(ScSignRequestKeys.fee.index)] = CborString(fee!);
    }
    if (outputs != null) {
      map[CborSmallInt(ScSignRequestKeys.outputs.index)] = cborBytes(RegistryItem.jsonBytes(outputs));
    }
    if (chain.isNotEmpty) {
      map[CborSmallInt(ScSignRequestKeys.chain.index)] = CborString(chain);
    }
    if (crossChainFee != null) {
      map[CborSmallInt(ScSignRequestKeys.crossChainFee.index)] = CborString(crossChainFee!);
    }

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final signingPayloadEncoding = _readSigningPayloadEncoding(map);
    return ScSignRequest(
      uuid: RegistryItem.readBytes(map, ScSignRequestKeys.uuid.index),
      xfp: RegistryItem.readText(map, ScSignRequestKeys.xfp.index),
      path: RegistryItem.readText(map, ScSignRequestKeys.path.index),
      address: RegistryItem.readText(map, ScSignRequestKeys.address.index),
      publicKey: RegistryItem.readText(map, ScSignRequestKeys.publicKey.index),
      signingPayloadData: _readSigningPayloadData(map, signingPayloadEncoding),
      signingPayloadEncoding: signingPayloadEncoding,
      fee: RegistryItem.readOptionalText(map, ScSignRequestKeys.fee.index),
      outputs: RegistryItem.readOptionalJsonList(map, ScSignRequestKeys.outputs.index),
      origin: RegistryItem.readOptionalText(map, ScSignRequestKeys.origin.index),
      chain: RegistryItem.readOptionalText(map, ScSignRequestKeys.chain.index) ?? '',
      crossChainFee: RegistryItem.readOptionalText(map, ScSignRequestKeys.crossChainFee.index),
    );
  }

  static ScSignRequest fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<ScSignRequest>(
      cborPayload,
      ScSignRequest(
        xfp: '',
        path: '',
        address: '',
        publicKey: '',
        signingPayloadData: const {},
      ),
    );
  }

  static ScSignRequest fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.SC_SIGN_REQUEST.type) {
      throw InvalidTypeURException(expected: RegistryType.SC_SIGN_REQUEST.type, actual: ur.type);
    }
    return fromCBOR(ur.payload);
  }

  static UR buildUR({
    String? requestId,
    required String xfp,
    required String path,
    required String address,
    required String publicKey,
    required Map<String, dynamic> signingPayloadData,
    ScSigningPayloadEncoding signingPayloadEncoding = ScSigningPayloadEncoding.json,
    String? fee,
    List<dynamic>? outputs,
    String? origin,
    String chain = '',
    String? crossChainFee,
  }) {
    return ScSignRequest(
      uuid: requestId != null ? Uint8List.fromList(uuidParse(requestId)) : null,
      xfp: xfp,
      path: path,
      address: address,
      publicKey: publicKey,
      signingPayloadData: signingPayloadData,
      signingPayloadEncoding: signingPayloadEncoding,
      fee: fee,
      outputs: outputs,
      origin: origin,
      chain: chain,
      crossChainFee: crossChainFee,
    ).toUR();
  }

  Uint8List _encodeSigningPayload(Uint8List jsonBytes) {
    return switch (signingPayloadEncoding) {
      ScSigningPayloadEncoding.json => jsonBytes,
      ScSigningPayloadEncoding.zlibJsonV1 => Uint8List.fromList(ZLibCodec(level: 6).encode(jsonBytes)),
    };
  }

  static ScSigningPayloadEncoding _readSigningPayloadEncoding(CborMap map) {
    final key = ScSignRequestKeys.signingPayloadEncoding.index;
    if (!RegistryItem.hasKey(map, key)) return ScSigningPayloadEncoding.json;

    final wireValue = RegistryItem.readInt(map, key);
    if (wireValue == _zlibJsonV1WireValue) return ScSigningPayloadEncoding.zlibJsonV1;
    throw ArgumentError('Unsupported SC signing payload encoding: $wireValue');
  }

  static Map<String, dynamic> _readSigningPayloadData(CborMap map, ScSigningPayloadEncoding encoding) {
    final bytes = RegistryItem.readBytes(map, ScSignRequestKeys.signingPayloadData.index);
    if (encoding == ScSigningPayloadEncoding.json) {
      return _jsonMapFromBytes(bytes);
    }

    final sink = _BoundedBytesSink(maxLength: maxSigningPayloadBytes);
    final decoder = ZLibCodec().decoder.startChunkedConversion(sink);
    decoder.add(bytes);
    decoder.close();
    return _jsonMapFromBytes(sink.bytes);
  }

  static Map<String, dynamic> _jsonMapFromBytes(Uint8List bytes) {
    final value = jsonDecode(utf8.decode(bytes));
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ArgumentError('SC signing payload must be a JSON map');
  }
}

// Zlib decoder 每产出一个 chunk 就先检查累计长度，避免压缩炸弹完整落入内存。
final class _BoundedBytesSink extends ByteConversionSink {
  _BoundedBytesSink({required this.maxLength});

  final int maxLength;
  final BytesBuilder _builder = BytesBuilder(copy: false);
  int _length = 0;

  Uint8List get bytes => _builder.takeBytes();

  @override
  void add(List<int> chunk) {
    final nextLength = _length + chunk.length;
    if (nextLength > maxLength) {
      throw ArgumentError('SC signing payload exceeds $maxLength decompressed bytes');
    }
    _builder.add(chunk);
    _length = nextLength;
  }

  @override
  void close() {}
}
