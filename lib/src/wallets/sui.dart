import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';

/// Create a **sui** wallet using mnemonic or private key, 
/// with a signature algorithm of [ED25519].
class SuiCoin extends WalletType {
  static final SUI_ADDRESS_LENGTH = 32;
  final _default = WalletSetting(bip44Path: SUI_PATH);
  WalletSetting? setting;

  SuiCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<SuiCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = SuiCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory SuiCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = SuiCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    final privateKey =
        await HDWallet.bip44DerivePath(mnemonic, setting!.bip44Path);
    return Uint8List.fromList(privateKey);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return ED25519.privateKeyToPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    final hash = publicKeyToBlack2bHash(publicKey);
    final slicedHash = hash.substring(0, SUI_ADDRESS_LENGTH * 2);
    return '0x${slicedHash.toLowerCase().padLeft(SUI_ADDRESS_LENGTH * 2, '0')}';
  }

  @override
  String sign(String message) {
    final signedMessage = ED25519.sign(privateKey, dynamicToUint8List(message));
    return dynamicToString(signedMessage);
  }

  @override
  bool verify(String signature, String message) {
    return ED25519.verify(publicKey, signature, message);
  }

  String publicKeyToBlack2bHash(Uint8List publicKey) {
    final suiBytes = Uint8List(publicKey.length + 1);
    suiBytes[0] = 0;
    suiBytes.setRange(1, suiBytes.length, publicKey);
    final hash = Blake2b.getBlake2bHash(suiBytes);
    final hexes =
        List<String>.generate(256, (i) => i.toRadixString(16).padLeft(2, '0'));
    String hex = '';
    for (int i = 0; i < hash.length; i++) {
      hex += hexes[hash[i]];
    }
    return hex;
  }
}
