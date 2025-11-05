import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/bip32/src/utils/base58.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **trx** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of [base58].
class TrxCoin extends WalletType {
  final _default = WalletSetting(bip44Path: TRX_PATH);
  WalletSetting? setting;

  TrxCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<TrxCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = TrxCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory TrxCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = TrxCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    return HDWallet.bip32DerivePath(mnemonic, setting!.bip44Path);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return EcdaSignature.getUnCompressedPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    final input = Uint8List.fromList(publicKey.skip(1).toList());
    final result = getKeccakDigest(input);
    final addr = result.skip(result.length - 20).toList();
    return Base58CheckCodec.bitcoin().encode(Base58CheckPayload(0x41, addr));
  }

  @override
  String sign(String message) {
    return EcdaSignature.sign(message, privateKey).getSignature();
  }

  @override
  bool verify(String signature, String message) {
    return EcdaSignature.verify(message, publicKey, signature);
  }
}
