import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:bip39/bip39.dart' as bip39;

/// Generator special address such as:
/// 0x0000************************,
/// Support address type: evm
/// Return [SpecialAccount]
class AccountGenerator {
  static List<SpecialAccount> getSpecialEthAddress(
      {String regex = r'0x0.*$', int num = 1}) {
    final List<SpecialAccount> specialAccounts = [];
    int i = 0;
    while (true) {
      final mnemonic = bip39.generateMnemonic();
      final bip44Path = "m/44'/60'/0'/0/0";
      final Uint8List customPrivateKey =
          HDWallet.bip32DerivePath(mnemonic, bip44Path);
      final Uint8List compressPublicKey = EcdaSignature.privateKeyToPublicKey(
          customPrivateKey,
          compress: false);
      final Uint8List addressBytes = getKeccakDigest(compressPublicKey);
      final String address = addressBytes.sublist(12).toHex();

      if (RegExp(regex).hasMatch(address)) {
        specialAccounts
            .add(SpecialAccount(mnemonic: mnemonic, address: address));
      }
      if (specialAccounts.length >= num) {
        break;
      }
      i++;
    }
    // ignore: avoid_print
    print(i);
    return specialAccounts;
  }
}

/// Include [mnemonic] and [address]
class SpecialAccount {
  final String mnemonic;
  final String address;

  SpecialAccount({required this.mnemonic, required this.address});
}
