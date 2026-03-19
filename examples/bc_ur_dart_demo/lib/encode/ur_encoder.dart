import 'dart:typed_data';
import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:convert/convert.dart';
import 'package:crypto_wallet_util/crypto_utils.dart' show BIP32;
import 'package:crypto_wallet_util/transaction.dart' show GsplItem, GsplTxData, BtcSignDataType;

/// 统一编码入口：接受类型字符串 + 参数 Map，返回可调用 next() 的 UR 对象。
///
/// 旧式（ETH/PSBT/GSPL/HDKey/MultiAccounts）：对象本身 IS-A UR，直接返回。
/// 新式（Cosmos/Sol/Tron/Alph）：.toUR() 转换后返回，调用方无感知。
/// => 调用方永远只拿到 UR，调 ur.next() 即可。
UR buildUR(String type, Map<String, dynamic> params) {
  switch (type.toLowerCase()) {
    // ── ETH ──────────────────────────────────────────────────
    case 'eth-sign-request':
      return EthSignRequestUR.fromMessage(
        dataType: _ethDataType(params['dataType'] as String? ?? 'ETH_TRANSACTION_DATA'),
        address: params['address'] as String,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        signData: params['signData'] as String,
        chainId: int.parse(params['chainId']?.toString() ?? '1'),
        origin: params['origin'] as String? ?? '',
      );

    // ── Cosmos ────────────────────────────────────────────────
    case 'cosmos-sign-request':
      return CosmosSignRequest.generateSignRequest(
        signData: params['signData'] as String,
        path: params['path'] as String,
        chain: params['chain'] as String,
        xfp: params['xfp'] as String,
        origin: params['origin'] as String?,
        fee: params['fee'] != null ? int.tryParse(params['fee'].toString()) : null,
      );

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

    // ── Tron ──────────────────────────────────────────────────
    case 'tron-sign-request':
      return TronSignRequest.generateSignRequest(
        signData: params['signData'] as String,
        path: params['path'] as String,
        xfp: params['xfp'] as String,
        origin: params['origin'] as String?,
        fee: params['fee'] != null ? int.tryParse(params['fee'].toString()) : null,
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

    // ── CryptoHDKey ───────────────────────────────────────────
    case 'crypto-hdkey':
      final wallet = BIP32.fromBase58(params['xpub'] as String);
      return CryptoHDKeyUR.fromWallet(
        name: params['name'] as String? ?? 'wallet',
        path: params['path'] as String,
        wallet: wallet,
        xfp: params['xfp'] as String?,
      );

    // ── CryptoMultiAccounts ───────────────────────────────────
    case 'crypto-multi-accounts':
      final xfpHex = params['masterFingerprint'] as String;
      final masterFp = BigInt.parse(xfpHex, radix: 16);

      final rawChains = (params['chains'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final chains = rawChains.map((c) {
        final wallet = BIP32.fromBase58(c['xpub'] as String);
        return CryptoAccountItemUR.fromAccount(
          path: c['path'] as String,
          chains: List<String>.from(c['chains'] as List),
          publicKey: wallet.publicKey,
          wallet: wallet,
        );
      }).toList();

      return CryptoMultiAccountsUR.fromWallet(
        masterFingerprint: masterFp,
        device: params['device'] as String? ?? 'FxWallet',
        walletName: params['walletName'] as String? ?? 'Demo',
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

    // ── PSBT Signature ────────────────────────────────────────
    case 'psbt-signature':
      return _buildPsbtSignature(params);

    // ── GSPL Signature ────────────────────────────────────────
    case 'btc-signature':
      return _buildGsplSignature(params);

    default:
      throw UnsupportedError('Unknown UR type: $type');
  }
}

// ── Signature 构建辅助 ────────────────────────────────────────

/// 将 hex requestId 转为 Uint8List uuid（可为 null）
Uint8List? _uuidBytes(String? requestId) {
  if (requestId == null || requestId.isEmpty) return null;
  return Uint8List.fromList(hex.decode(requestId.replaceAll('0x', '')));
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

