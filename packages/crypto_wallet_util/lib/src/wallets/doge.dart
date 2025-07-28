import 'package:crypto_wallet_util/src/config/chain/btc/doge.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_base_hd/src/crypto/keypair/ec_private.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Create a **doge** wallet using mnemonic or private key,
/// with a signature algorithm of [EcdaSignature] and an address type of [doge]

class DogeCoin extends WalletType {
  final _defaultWalletSetting = DOGEChain().mainnet;
  late WalletSetting setting;
  DogeCoin({setting}) {
    this.setting = setting ?? _defaultWalletSetting;
  }

  static Future<DogeCoin> fromMnemonic(String mnemonic, [WalletSetting? setting]) async {
    final wallet = DogeCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory DogeCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = DogeCoin(setting: setting);
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
    final addressBytes = sha160fromByte(publicKey);
    Uint8List versionedHash = Uint8List(21);
    versionedHash[0] = setting.networkType!.pubKeyHash;
    versionedHash.setRange(1, 21, addressBytes);
    return getBase58Address(versionedHash);
  }

  @override
  String sign(String message) {
    final ecPrivateKey = ECPrivate.fromBytes(privateKey);
    return ecPrivateKey.signInput(message.toUint8List()).toHex();
  }

  @override
  bool verify(String signature, String message) {
    return EcdaSignature.verify(message, publicKey, signature);
  }
}
