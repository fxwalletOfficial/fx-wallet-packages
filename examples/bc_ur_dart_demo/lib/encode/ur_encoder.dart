import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:convert/convert.dart';
import 'package:crypto_wallet_util/crypto_utils.dart' show BIP32;
import 'package:crypto_wallet_util/transaction.dart' show GsplItem, GsplTxData, BtcSignDataType, Eip1559TxData, Eip7702TxData, Eip7702Authorization, LegacyTxData, EthTxDataRaw, TxNetwork;

/// 统一编码入口：接受类型字符串 + 参数 Map，返回可调用 next() 的 UR 对象。
///
/// 旧式（ETH/PSBT/GSPL/HDKey/MultiAccounts）：对象本身 IS-A UR，直接返回。
/// 新式（Cosmos/Sol/Tron/Alph）：.toUR() 转换后返回，调用方无感知。
/// => 调用方永远只拿到 UR，调 ur.next() 即可。
UR buildUR(String type, Map<String, dynamic> params) {
  switch (type.toLowerCase()) {
    // ── ETH ──────────────────────────────────────────────────
    case 'eth-sign-request':
      // 检测是否传入交易字段，使用 fromTypedTransaction
      if (params['txType'] != null && (params['to'] != null && params['value'] != null)) {
        // 交易构建器模式：传入交易字段，由 encoder 构建 EthTxData
        return _buildEthTxRequest(params);
      }

      final signData = params['signData'] as String? ?? '';
      if (signData.isNotEmpty) {
        // 传统模式：直接传入 hex
        return EthSignRequestUR.fromMessage(
          dataType: _ethDataType(params['dataType'] as String? ?? 'ETH_TRANSACTION_DATA'),
          address: params['address'] as String? ?? '',
          path: params['path'] as String? ?? "m/44'/60'/0'/0/0",
          xfp: params['xfp'] as String? ?? '',
          signData: params['signData'] as String? ?? '',
          chainId: int.parse(params['chainId']?.toString() ?? '1'),
          origin: params['origin'] as String? ?? '',
        );
      }

      throw ArgumentError('Either signData or transaction fields must be provided');

    // ── Cosmos ────────────────────────────────────────────────
    case 'cosmos-sign-request':
      return CosmosSignRequest.generateSignRequest(
        signData: params['signData'] as String,
        path: params['path'] as String,
        chain: params['chain'] as String,
        xfp: params['xfp'] as String,
        origin: params['origin'] as String?,
        fee: _parseIntWithHex(params['fee']),
      );

    case 'keystone-cosmos-sign-request':
      return _buildKeystoneCosmosSignRequest(params);

    // ── Solana ────────────────────────────────────────────────
    case 'sol-sign-request':
      return SolSignRequest.generateSignRequest(
        signData: params['signData'] as String,
        signType: _solSignType(params['signType'] as String? ?? 'transaction'),
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        outputAddress: params['outputAddress'] as String?,
        contractAddress: params['contractAddress'] as String?,
        origin: params['origin'] as String?,
        fee: params['fee'] != null ? int.tryParse(params['fee'].toString()) : null,
      );

    case 'keystone-sol-sign-request':
      final signType = params['signType'] as String? ?? 'transaction';
      final signDataHex = params['signDataHex'] as String? ?? params['signData'] as String;
      if (signType == 'message') {
        return KeystoneSolSignRequest.buildMessageRequest(
          messageHex: signDataHex,
          path: params['path'] as String,
          xfp: params['xfp'] as String,
          address: params['address'] as String?,
          origin: params['origin'] as String?,
        );
      }
      return KeystoneSolSignRequest.buildTransactionRequest(
        txHex: signDataHex,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        address: params['address'] as String?,
        origin: params['origin'] as String?,
      );

    // ── Tron ──────────────────────────────────────────────────
    case 'tron-sign-request':
      return TronSignRequest.generateSignRequest(
        signData: params['signData'] as String,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        origin: params['origin'] as String?,
        fee: _parseIntWithHex(params['fee']),
      );

    case 'keystone-tron-sign-request':
      final tokenInfo = params['tokenInfo'] is Map ? Map<String, dynamic>.from(params['tokenInfo'] as Map) : null;
      return KeystoneTronSignRequest.buildUR(
        requestId: params['requestId'] as String,
        signDataHex: params['signDataHex'] as String,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        tokenInfo: tokenInfo == null
            ? null
            : KeystoneTronTokenInfo(
                name: tokenInfo['name'] as String? ?? '',
                symbol: tokenInfo['symbol'] as String? ?? '',
                decimals: int.tryParse(tokenInfo['decimals']?.toString() ?? '') ?? 0,
              ),
        origin: params['origin'] as String?,
      );

    // ── Aleo (Alph) ───────────────────────────────────────────
    case 'alph-sign-request':
      final rawOutputs = params['outputs'] as List?;
      final outputs = rawOutputs?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return AlphSignRequest.generateSignRequest(
        signData: params['signData'] as String,
        dataType: _gsplDataType(params['dataType'] as String? ?? 'transaction'),
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        outputs: outputs,
        origin: params['origin'] as String?,
      );

    // ── Sia ──────────────────────────────────────────────────
    case 'sc-sign-request':
    case 'scp-sign-request':
      return ScSignRequest.buildUR(
        requestId: params['requestId'] as String?,
        xfp: params['xfp'] as String,
        path: params['path'] as String,
        address: params['address'] as String,
        publicKey: params['publicKey'] as String,
        signingPayloadData: Map<String, dynamic>.from(params['signingPayloadData'] as Map),
        fee: params['fee'] as String?,
        outputs: params['outputs'] as List?,
        origin: params['origin'] as String?,
        chain: params['chain'] as String? ?? (type.toLowerCase() == 'scp-sign-request' ? 'scp' : 'sc'),
        crossChainFee: params['crossChainFee'] as String?,
      );

    // ── PSBT (Bitcoin) ────────────────────────────────────────
    case 'psbt-sign-request':
      return PsbtSignRequestUR.fromTypedTransaction(
        psbt: params['psbt'] as String,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        origin: params['origin'] as String? ?? '',
      );

    // ── GSPL (Bitcoin variant) ────────────────────────────────
    case 'btc-sign-request':
      final rawInputs = (params['inputs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final inputs = rawInputs
          .map((e) => GsplItem(
                path: e['path'] as String?,
                address: e['address'] as String?,
                amount: e['amount'] != null ? int.tryParse(e['amount'].toString()) : null,
              ))
          .toList();

      GsplItem? change;
      final rawChange = params['change'] as Map?;
      if (rawChange != null) {
        change = GsplItem(
          path: rawChange['path'] as String?,
          address: rawChange['address'] as String?,
          amount: rawChange['amount'] != null ? int.tryParse(rawChange['amount'].toString()) : null,
        );
      }

      return GsplSignRequestUR.fromTypedTransaction(
        hex: params['hex'] as String,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        origin: params['origin'] as String? ?? '',
        inputs: inputs,
        change: change,
      );

    case 'bch-sign-request':
    case 'doge-sign-request':
      final inputs = (params['inputs'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((e) => BchInput(
                hash: e['hash'] as String,
                index: e['index'] != null ? int.tryParse(e['index'].toString()) : null,
                value: int.parse(e['value'].toString()),
                pubkey: e['pubkey'] as String,
                ownerKeyPath: e['ownerKeyPath'] as String,
              ))
          .toList();
      final outputs = (params['outputs'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((e) => BchOutput(
                address: e['address'] as String,
                value: int.parse(e['value'].toString()),
                isChange: e['isChange'] == true || e['isChange']?.toString() == 'true',
                changeAddressPath: e['changeAddressPath'] as String?,
              ))
          .toList();
      return BchSignRequestUR.fromTransaction(
        inputs: inputs,
        outputs: outputs,
        fee: int.parse(params['fee'].toString()),
        xfp: params['xfp'] as String,
        hdPath: params['hdPath'] as String,
        requestId: params['requestId'] as String?,
        origin: params['origin'] as String?,
        coinCode: params['coinCode'] as String? ?? (type.toLowerCase() == 'doge-sign-request' ? 'DOGE' : 'BCH'),
      );

    // ── CryptoHDKey ───────────────────────────────────────────
    case 'crypto-hdkey':
      return _buildCryptoHDKey(params);

    // ── CryptoAccount ────────────────────────────────────────
    case 'crypto-account':
      final xfpHex = params['masterFingerprint'] as String;
      final masterFp = BigInt.parse(xfpHex, radix: 16);

      final rawOutputs = (params['outputs'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final outputs = rawOutputs.map(_buildCryptoHDKey).toList();

      return CryptoAccountUR.fromWallet(
        masterFingerprint: masterFp,
        outputs: outputs,
        xfpFormat: params['xfpFormat'] as String?,
      );

    // ── CryptoMultiAccounts ───────────────────────────────────
    case 'crypto-multi-accounts':
      final xfpHex = params['masterFingerprint'] as String;
      final masterFp = BigInt.parse(xfpHex, radix: 16);

      final rawChains = (params['chains'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final chains = rawChains.map(_buildCryptoHDKey).toList();

      return CryptoMultiAccountsUR.fromWallet(
        masterFingerprint: masterFp,
        device: params['device'] as String? ?? 'FxWallet',
        deviceId: params['deviceId'] as String?,
        version: params['version'] as String? ?? '1.0.0',
        walletName: params['walletName'] as String?,
        xfpFormat: params['xfpFormat'] as String?,
        chains: chains,
      );

    // ── ETH Signature ────────────────────────────────────────
    case 'eth-signature':
      return _buildEthSignature(params);

    // ── Cosmos Signature ──────────────────────────────────────
    case 'cosmos-signature':
      return CosmosSignature(
        uuid: _uuidBytes(params['requestId'] as String?),
        signature: _hex(params['signature'] as String),
        origin: params['origin'] as String?,
      ).toUR();

    // ── Solana Signature ──────────────────────────────────────
    case 'sol-signature':
      return SolSignature(
        uuid: _uuidBytes(params['requestId'] as String?),
        signature: _hex(params['signature'] as String),
        origin: params['origin'] as String?,
      ).toUR();

    // ── Tron Signature ────────────────────────────────────────
    case 'tron-signature':
      return TronSignature(
        uuid: _uuidBytes(params['requestId'] as String?),
        signature: _hex(params['signature'] as String),
        origin: params['origin'] as String?,
      ).toUR();

    // ── Aleo Signature ────────────────────────────────────────
    case 'alph-signature':
      return AlphSignature(
        uuid: _uuidBytes(params['requestId'] as String?),
        signature: _hex(params['signature'] as String),
        origin: params['origin'] as String?,
      ).toUR();

    // ── Sia Signature ────────────────────────────────────────
    case 'sc-signature':
      return ScSignature.buildUR(
        requestId: params['requestId'] as String?,
        broadcastTx: Map<String, dynamic>.from(params['broadcastTx'] as Map),
        origin: params['origin'] as String?,
      );

    // ── PSBT Signature ────────────────────────────────────────
    case 'psbt-signature':
      return _buildPsbtSignature(params);

    case 'crypto-psbt':
      return UR.fromCBOR(
        type: RegistryType.CRYPTO_PSBT.type,
        value: CborBytes(_hex(params['signature'] as String)),
      );

    // ── GSPL Signature ────────────────────────────────────────
    case 'btc-signature':
      return _buildGsplSignature(params);

    case 'bch-signature':
      return BchSignatureUR.fromSignature(
        requestId: params['requestId'] as String,
        rawTx: params['rawTx'] as String,
      );

    case 'keystone-tron-sign-result':
      return _buildKeystoneTronSignResult(params);

    case 'xrp-sign-request':
      return KeystoneXrpSignRequestBytes.buildUR(
        transaction: Map<String, dynamic>.from(params['transaction'] as Map),
      );

    case 'xrp-signature':
      return _buildBytesJson({
        'signature': params['signature'] as String? ?? '',
        'publicKey': params['publicKey'] as String? ?? '',
        'signedBlob': params['signedBlob'] as String? ?? '',
        'txHash': params['txHash'] as String? ?? '',
      });

    case 'xrp-account':
      return _buildBytesJson({
        'address': params['address'] as String,
        'pubkey': params['publicKey'] as String,
      });

    default:
      throw UnsupportedError('Unknown UR type: $type');
  }
}

CryptoHDKeyUR _buildCryptoHDKey(Map<String, dynamic> params) {
  final xpub = params['xpub'] as String? ?? '';
  final wallet = xpub.isEmpty ? null : BIP32.fromBase58(xpub);
  final publicKey = params['publicKey'] as String? ?? '';
  final chainCode = params['chainCode'] as String? ?? '';

  if (wallet == null && publicKey.isEmpty) {
    throw ArgumentError('crypto-hdkey requires either xpub or publicKey');
  }

  final name = params['name'] as String? ?? '';
  return CryptoHDKeyUR.fromWallet(
    name: name.isEmpty ? 'account' : name,
    path: params['path'] as String,
    wallet: wallet,
    publicKey: wallet == null ? _hex(publicKey) : null,
    chainCode: wallet == null && chainCode.isNotEmpty ? _hex(chainCode) : null,
    xfp: params['xfp'] as String?,
    sourceFingerprint: params['sourceFingerprint'] as String?,
    xfpFormat: params['xfpFormat'] as String?,
    childrenPath: params['childrenPath'] as String?,
    note: params['note'] as String?,
  );
}

UR _buildKeystoneCosmosSignRequest(Map<String, dynamic> params) {
  final dataType = params['dataType'] as String? ?? 'amino';
  final signDataHex = params['signDataHex'] as String? ?? params['signData'] as String;
  switch (dataType) {
    case 'direct':
      return KeystoneCosmosSignRequest.buildDirectRequest(
        signDataHex: signDataHex,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        address: params['address'] as String?,
        origin: params['origin'] as String?,
      );
    case 'textual':
      return KeystoneCosmosSignRequest.buildTextualRequest(
        signDataHex: signDataHex,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        address: params['address'] as String?,
        origin: params['origin'] as String?,
      );
    case 'message':
      return KeystoneCosmosSignRequest.buildMessageRequest(
        signDataHex: signDataHex,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        address: params['address'] as String?,
        origin: params['origin'] as String?,
      );
    case 'amino':
    default:
      return KeystoneCosmosSignRequest.buildAminoRequest(
        signDataHex: signDataHex,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        address: params['address'] as String?,
        origin: params['origin'] as String?,
      );
  }
}

UR _buildKeystoneTronSignResult(Map<String, dynamic> params) {
  final result = _protoMessage([
    _protoString(1, params['requestId'] as String),
    _protoString(2, params['txId'] as String? ?? ''),
    _protoString(3, params['rawTx'] as String),
  ]);
  final payload = _protoMessage([
    _protoVarintField(1, 9),
    _protoBytesField(7, result),
  ]);
  final base = _protoMessage([
    _protoVarintField(1, 2),
    _protoString(2, 'QrCode Protocol'),
    _protoBytesField(3, payload),
  ]);

  return UR.fromCBOR(
    type: RegistryType.KEYSTONE_SIGNATURE.type,
    value: CborMap({
      CborSmallInt(1): CborBytes(Uint8List.fromList(GZipCodec().encode(base))),
    }),
  );
}

UR _buildBytesJson(Map<String, dynamic> payload) {
  return UR.fromCBOR(
    type: RegistryType.BYTES.type,
    value: CborBytes(utf8.encode(jsonEncode(payload))),
  );
}

Uint8List _protoMessage(List<Uint8List> fields) {
  return Uint8List.fromList(fields.expand((field) => field).toList());
}

Uint8List _protoString(int fieldNumber, String value) {
  return _protoBytesField(fieldNumber, utf8.encode(value));
}

Uint8List _protoBytesField(int fieldNumber, List<int> value) {
  return Uint8List.fromList([
    ..._encodeVarint((fieldNumber << 3) | 2),
    ..._encodeVarint(value.length),
    ...value,
  ]);
}

Uint8List _protoVarintField(int fieldNumber, int value) {
  return Uint8List.fromList([
    ..._encodeVarint((fieldNumber << 3) | 0),
    ..._encodeVarint(value),
  ]);
}

List<int> _encodeVarint(int value) {
  final result = <int>[];
  var current = value;
  while (true) {
    if ((current & ~0x7f) == 0) {
      result.add(current);
      return result;
    }
    result.add((current & 0x7f) | 0x80);
    current >>= 7;
  }
}

// ── Signature 构建辅助 ────────────────────────────────────────

/// 将 hex requestId 转为 Uint8List uuid（可为 null）
Uint8List? _uuidBytes(String? requestId) {
  if (requestId == null || requestId.isEmpty) return null;
  return Uint8List.fromList(hex.decode(requestId.replaceAll('0x', '')));
}

/// Parse int from decimal text or 0x-prefixed hex text.
int? _parseIntWithHex(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final normalized = raw.toLowerCase();
  if (normalized.startsWith('0x')) {
    final hexValue = normalized.substring(2);
    if (hexValue.isEmpty) return null;
    return int.tryParse(hexValue, radix: 16);
  }

  return int.tryParse(raw);
}

/// hex string → Uint8List，容忍 0x 前缀
Uint8List _hex(String h) => Uint8List.fromList(hex.decode(h.replaceAll('0x', '')));

UR _buildEthSignature(Map<String, dynamic> params) {
  final uuid = _uuidBytes(params['requestId'] as String?);
  final sig = _hex(params['signature'] as String);
  final urObj = UR.fromCBOR(
    type: 'eth-signature',
    value: CborMap({
      if (uuid != null) CborSmallInt(1): CborBytes(uuid, tags: [37]),
      CborSmallInt(2): CborBytes(sig),
    }),
  );
  return urObj;
}

UR _buildPsbtSignature(Map<String, dynamic> params) {
  final uuid = _uuidBytes(params['requestId'] as String?);
  final sig = _hex(params['signature'] as String);
  return UR.fromCBOR(
    type: 'psbt-signature',
    value: CborMap({
      if (uuid != null) CborSmallInt(1): CborBytes(uuid, tags: [37]),
      CborSmallInt(2): CborBytes(sig),
    }),
  );
}

UR _buildGsplSignature(Map<String, dynamic> params) {
  final uuid = _uuidBytes(params['requestId'] as String?);
  final signedHex = params['signedHex'] as String;
  final gspl = GsplTxData(
    dataType: BtcSignDataType.TRANSACTION,
    inputs: [],
    hex: signedHex,
  );
  return UR.fromCBOR(
    type: 'btc-signature',
    value: CborMap({
      if (uuid != null) CborSmallInt(1): CborBytes(uuid, tags: [37]),
      CborSmallInt(2): gspl.toCbor(),
    }),
  );
}

// ── 枚举转换辅助 ──────────────────────────────────────────────

EthSignDataType _ethDataType(String name) {
  return EthSignDataType.values.firstWhere(
    (e) => e.name == name,
    orElse: () => EthSignDataType.ETH_TRANSACTION_DATA,
  );
}

SignType _solSignType(String name) {
  return SignType.values.firstWhere(
    (e) => e.name == name,
    orElse: () => SignType.transaction,
  );
}

GsplDataType _gsplDataType(String name) {
  return GsplDataType.values.firstWhere(
    (e) => e.name == name,
    orElse: () => GsplDataType.transaction,
  );
}

/// 使用 fromTypedTransaction 构建 ETH 交易请求
UR _buildEthTxRequest(Map<String, dynamic> params) {
  final chainId = int.parse(params['chainId']?.toString() ?? '1');
  final txType = params['txType'] as String? ?? 'legacy';
  final to = params['to'] as String? ?? '';
  final value = params['value'] as String? ?? '0';
  final gasLimit = int.tryParse(params['gasLimit']?.toString() ?? '21000') ?? 21000;
  final nonce = int.tryParse(params['nonce']?.toString() ?? '0') ?? 0;
  final data = params['data'] as String? ?? '';
  final origin = params['origin'] as String? ?? '';
  final path = params['path'] as String? ?? "m/44'/60'/0'/0/0";
  final xfp = (params['xfp'] as String?) ?? '';

  // 构建网络配置
  final network = TxNetwork(chainId: chainId);

  // 构建交易原始数据 - data 保持为 String，让库内部处理
  final txRaw = EthTxDataRaw(
    to: to.isNotEmpty ? to : '0x0000000000000000000000000000000000000000',
    value: BigInt.tryParse(value) ?? BigInt.zero,
    data: data, // String 类型，库内部会处理
    nonce: nonce,
    gasLimit: gasLimit,
  );

  EthTxData tx;
  if (txType == 'eip1559') {
    // EIP-1559 交易
    final maxFee = int.tryParse(params['maxFee']?.toString() ?? '0') ?? 0;
    final maxPriority = int.tryParse(params['maxPriority']?.toString() ?? '0') ?? 0;
    txRaw.maxFeePerGas = maxFee;
    txRaw.maxPriorityFeePerGas = maxPriority;
    tx = Eip1559TxData(data: txRaw, network: network);
  } else if (txType == 'eip7702') {
    // EIP-7702 交易
    final maxFee = int.tryParse(params['maxFee']?.toString() ?? '0') ?? 0;
    final maxPriority = int.tryParse(params['maxPriority']?.toString() ?? '0') ?? 0;
    txRaw.maxFeePerGas = maxFee;
    txRaw.maxPriorityFeePerGas = maxPriority;
    final eip7702Contract = params['eip7702Contract'] as String? ?? '0x0000000000000000000000000000000000000000';
    final gasPayerAddress = to.isNotEmpty ? to : '0x0000000000000000000000000000000000000000';

    // 构建 authorization
    final authorization = Eip7702Authorization(
      chainId: chainId,
      address: eip7702Contract,
      gasPayerAddress: gasPayerAddress,
      signerAddress: gasPayerAddress,
      signerNonce: nonce,
    );

    // 获取私钥进行签名（Demo 模式使用表单传入的私钥）
    final privKey = params['_testPrivKey'] as String?;
    if (privKey != null && privKey.isNotEmpty) {
      // 有私钥：签名 authorization
      final signedAuthorization = authorization.sign(privKey);
      tx = Eip7702TxData(data: txRaw, network: network, authorization: signedAuthorization);
    } else {
      // 无私钥：使用未签名的 authorization（仅用于演示）
      tx = Eip7702TxData(data: txRaw, network: network, authorization: authorization);
    }
  } else {
    // Legacy 交易
    final gasPrice = int.tryParse(params['gasPrice']?.toString() ?? '0') ?? 0;
    txRaw.gasPrice = gasPrice;
    tx = LegacyTxData(data: txRaw, network: network);
  }

  return EthSignRequestUR.fromTypedTransaction(
    tx: tx,
    address: params['address'] as String? ?? to,
    path: path,
    origin: origin,
    xfp: xfp,
  );
}
