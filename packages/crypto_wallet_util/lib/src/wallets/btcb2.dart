import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart' as blockchain;
import 'package:crypto_wallet_util/src/config/chain/btc/btcb2.dart';
import 'package:crypto_wallet_util/src/config/constants/constants.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_base_hd/src/crypto/keypair/ec_private.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Create a BTCB2 wallet using a mnemonic or private key.
///
/// BTCB2 uses Bitcoin mainnet BIP44/secp256k1/P2PKH rules for account
/// derivation. Its transaction signer is exposed separately so BTCB2 does
/// not accidentally use ordinary Bitcoin transaction sighash rules.
class Btcb2Coin extends WalletType {
  static const String defaultDerivationPath = BTC_PATH;

  Btcb2Coin({WalletSetting? setting})
    : setting = setting ?? BTCB2Chain().mainnet;

  final WalletSetting setting;

  static Future<Btcb2Coin> fromMnemonic(
    String mnemonic, [
    WalletSetting? setting,
  ]) async {
    final wallet = Btcb2Coin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory Btcb2Coin.fromPrivateKey(
    dynamic privateKey, [
    WalletSetting? setting,
  ]) {
    final wallet = Btcb2Coin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    if (setting.bip44Path != defaultDerivationPath) {
      throw ArgumentError(
        'BTCB2 only supports derivation path $defaultDerivationPath.',
      );
    }
    return HDWallet.bip32DerivePath(mnemonic, defaultDerivationPath);
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return EcdaSignature.privateKeyToPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    return addressFromPublicKeyBytes(publicKey);
  }

  @override
  String sign(String message) {
    final ecPrivateKey = ECPrivate.fromBytes(privateKey);
    return ecPrivateKey.signInput(message.toUint8List(), sigHash: 0x21).toHex();
  }

  @override
  bool verify(String signature, String message) {
    return EcdaSignature.verifyDerWithHashType(message, publicKey, signature);
  }

  /// Returns the Bitcoin mainnet P2PKH address for a compressed public key.
  static String addressFromPublicKeyBytes(List<int> publicKeyBytes) {
    final hash160 = sha160fromByte(Uint8List.fromList(publicKeyBytes));
    final versionedHash = Uint8List(21)
      ..[0] = 0x00
      ..setRange(1, 21, hash160);
    return getBase58Address(versionedHash);
  }

  /// Converts a Bitcoin mainnet address into its standard output script.
  ///
  /// BTCB2 signs P2PKH inputs in the first version, but accepts P2PKH, P2SH,
  /// SegWit v0 and Taproot destination outputs.
  static List<int> scriptPubKeyFromAddress(String address) {
    try {
      final decoded = blockchain.Base58Decoder.checkDecode(address);
      if (decoded.length == 21 && decoded.first == 0x00) {
        return [0x76, 0xa9, 0x14, ...decoded.sublist(1), 0x88, 0xac];
      }
      if (decoded.length == 21 && decoded.first == 0x05) {
        return [0xa9, 0x14, ...decoded.sublist(1), 0x87];
      }
    } catch (_) {
      // It may be a SegWit address; try Bech32/Bech32m below.
    }

    try {
      final decoded = blockchain.SegwitBech32Decoder.decode('bc', address);
      final version = decoded.$1;
      final program = decoded.$2;
      if (version < 0 ||
          version > 16 ||
          program.length < 2 ||
          program.length > 40) {
        throw const FormatException('Invalid SegWit witness program.');
      }
      if (version == 0 && program.length != 20 && program.length != 32) {
        throw const FormatException('Invalid SegWit v0 witness program.');
      }
      final versionOpcode = version == 0 ? 0x00 : 0x50 + version;
      return [versionOpcode, program.length, ...program];
    } catch (_) {
      throw FormatException('Unsupported Bitcoin mainnet address: $address');
    }
  }

  static bool isP2pkhScript(List<int> script) =>
      script.length == 25 &&
      script[0] == 0x76 &&
      script[1] == 0xa9 &&
      script[2] == 0x14 &&
      script[23] == 0x88 &&
      script[24] == 0xac;
}
