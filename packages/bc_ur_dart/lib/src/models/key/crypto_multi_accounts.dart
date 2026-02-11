import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:convert/convert.dart';
import 'package:crypto_wallet_util/crypto_utils.dart' show BIP32, HIGHEST_BIT;

const String CRYPTO_MULTI_ACCOUNTS = 'CRYPTO-MULTI-ACCOUNTS';

class CryptoMultiAccountsUR extends UR {
  final List<CryptoAccountItemUR> chains;
  final String masterFingerprint;
  final String device;
  final String walletName;

  CryptoMultiAccountsUR({required UR ur, required this.chains, required this.device, required this.walletName, required this.masterFingerprint}) : super(payload: ur.payload, type: ur.type);

  static CryptoMultiAccountsUR fromUR({required UR ur}) {
    if (ur.type.toUpperCase() != CRYPTO_MULTI_ACCOUNTS) throw Exception('Invalid type');
    final data = ur.decodeCBOR() as CborMap;

    final masterFingerprint = (data[CborSmallInt(1)] as CborInt).toBigInt();

    final chains = (data[CborSmallInt(2)] as CborList);
    final chainList = <CryptoAccountItemUR>[];

    for (final item in chains) {
      final chainInfo = CryptoAccountItemUR.fromCborMap(item as CborMap);
      if (chainInfo != null) chainList.add(chainInfo);
    }

    final name = data[CborSmallInt(3)].toString();
    final walletName = data[CborSmallInt(6)].toString();

    return CryptoMultiAccountsUR(ur: ur, chains: chainList, device: name, walletName: walletName, masterFingerprint: getXfp(masterFingerprint));
  }

  static CryptoMultiAccountsUR fromWallet({
    required BigInt masterFingerprint,
    required String device,
    required String walletName,
    String version = '1.0.0',
    required List<CryptoAccountItemUR> chains
  }) {
    final xfp = getXfp(masterFingerprint);

    final ur = UR.fromCBOR(
      type: CRYPTO_MULTI_ACCOUNTS,
      value: CborMap({
        CborSmallInt(1): CborInt(BigInt.parse(xfp, radix: 16)),
        CborSmallInt(2): CborList(chains.map((e) => e.decodeCBOR()).toList()),
        CborSmallInt(3): CborString(device),
        CborSmallInt(5): CborString(version),
        CborSmallInt(6): CborString(walletName)
      })
    );

    return CryptoMultiAccountsUR(ur: ur, chains: chains, device: device, walletName: walletName, masterFingerprint: xfp);
  }

  @override
  String toString() => '''
{
"masterFingerprint":"$masterFingerprint",
"device":"$device",
"walletName":"$walletName",
"chains":${chains.map((e) => e.toString()).join(',')}
}
  ''';
}

class CryptoAccountItemUR extends UR {
  final String path;
  final List<String> chains;
  final BIP32? wallet;
  final Uint8List publicKey;
  String coin;

  CryptoAccountItemUR({
    required this.path,
    required this.chains,
    required this.publicKey,
    this.wallet,
    this.coin = ''
  });

  CryptoAccountItemUR.fromAccount({
    required this.path,
    required this.chains,
    required this.publicKey,
    this.wallet,
    this.coin = '',
    List<int> tags = const []
  }) : super.fromCBOR(
    type: CRYPTO_MULTI_ACCOUNTS,
    value: CborMap({
      CborSmallInt(2): CborBool(false),
      CborSmallInt(3): CborBytes(publicKey),
      if (wallet != null) CborSmallInt(4): CborBytes(wallet.chainCode),
      CborSmallInt(6):  CborMap({
        CborSmallInt(1): CborList(getPath(path)),
        if (wallet != null) CborSmallInt(2): CborInt(BigInt.from(wallet.parentFingerprint))
      }, tags: [304]),
      if (wallet != null) CborSmallInt(8): CborInt(BigInt.from(wallet.parentFingerprint)),
      CborSmallInt(10): CborString(json.encode({'chain': chains}))
    }, tags: tags)
  );

  static CryptoAccountItemUR? fromCborMap(CborMap data) {
    // Public key.
    final publicKey = Uint8List.fromList((data[CborSmallInt(3)] as CborBytes).bytes);

    // Path.
    final components = (data[CborSmallInt(6)] as CborMap)[CborSmallInt(1)] as CborList;
    String path = 'm';
    int index = 0;
    for (final item in components) {
      if (item is CborSmallInt) {
        path += '/${item.value}';
        index = item.value;
      }

      if (item is CborBool && item.value) {
        path += "'";
        index += HIGHEST_BIT;
      }
    }

    BIP32? wallet;
    if (data[CborSmallInt(4)] != null) {
      final parentFingerprint = (data[CborSmallInt(8)] as CborInt).toInt();
      final chainCode = Uint8List.fromList((data[CborSmallInt(4)] as CborBytes).bytes);

      // BIP32 wallet.
      wallet = BIP32.fromPublicKey(publicKey, chainCode);
      wallet.parentFingerprint = parentFingerprint;
      wallet.depth = (components.length / 2).round();
      wallet.index = index;
    }

    // Note.
    final note = data[CborSmallInt(10)].toString();
    final chains = ((json.decode(note)['chain'] ?? []) as List).map((e) => e.toString()).toList();
    if (chains.isEmpty) return null;

    return CryptoAccountItemUR(path: path, wallet: wallet, chains: chains, publicKey: publicKey);
  }

  @override
  String toString() => '''
{
"derivationPath":"$path",
"masterFingerprint":"${hex.encode(wallet?.fingerprint ?? crypto.sha256.convert(publicKey).bytes.sublist(0, 4))}",
"extendedPublicKey": "${wallet?.toBase58()??''}",
"chainCode": "${hex.encode(wallet?.chainCode ?? Uint8List(0))}"
}''';
}
