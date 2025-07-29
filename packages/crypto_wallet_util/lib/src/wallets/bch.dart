import 'package:crypto_wallet_util/src/config/chain/btc/bch.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_base_hd/src/crypto/keypair/ec_private.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart' as btc;
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Create a **bch** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of [bch]
/// Schnorr for bch not implemented

class BchCoin extends WalletType {
  final _defaultWalletSetting = BCHChain().mainnet;
  final sighashType = btc.SIGHASH_ALL | btc.SIGHASH_BITCOINCASHBIP143;
  late WalletSetting setting;
  BchCoin({setting}) {
    this.setting = setting ?? _defaultWalletSetting;
  }

  static Future<BchCoin> fromMnemonic(String mnemonic, [WalletSetting? setting]) async {
    final wallet = BchCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory BchCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = BchCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    return HDWallet.bip32DerivePath(mnemonic, setting.bip44Path);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return EcdaSignature.privateKeyToPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    // First generate Legacy format address
    final addressBytes = sha160fromByte(publicKey);
    Uint8List versionedHash = Uint8List(21);
    versionedHash[0] = setting.networkType!.pubKeyHash;
    versionedHash.setRange(1, 21, addressBytes);
    final legacyAddress = getBase58Address(versionedHash);
    
    // Use legacyToBch method to convert to BCH CashAddr format
    return btc.Address.legacyToBch(
      address: legacyAddress, 
      prefix: setting.prefix
    );
  }

  @override
  String sign(String message) {
    final ecPrivateKey = ECPrivate.fromBytes(privateKey);
    return ecPrivateKey.signInput(message.toUint8List(), sigHash: sighashType).toHex();
  }

  @override
  bool verify(String signature, String message) {
    return EcdaSignature.verify(message, publicKey, signature);
  }
}
