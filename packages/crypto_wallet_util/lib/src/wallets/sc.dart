import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Create a **sc** wallet using mnemonic or private key, 
/// with a signature algorithm of [ED25519].
class SiaCoin extends WalletType {
  static final SC_ADDRESS_LENGTH = 32;
  static final SC_INDEX = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0]);
  static final TIME_LOCK_HASH =
      '5187b7a8021bf4f2c004ea3a54cfece1754f11c7624d2363c7f4cf4fddd1441e';
  static final SIG_HASH =
      'b36010eb285c154a8cd63084acbe7eac0c4d625ab4e1a76e624a8798cb63497b';

  final _default = WalletSetting(bip44Path: '');
  WalletSetting? setting;

  SiaCoin({setting}) {
    this.setting = setting ?? _default;
  }

  static Future<SiaCoin> fromMnemonic(String mnemonic,
      [WalletSetting? setting]) async {
    final wallet = SiaCoin(setting: setting);
    await wallet.initFromMnemonic(mnemonic);
    return wallet;
  }

  factory SiaCoin.fromPrivateKey(dynamic privateKey, [WalletSetting? setting]) {
    final wallet = SiaCoin(setting: setting);
    wallet.initFromPrivateKey(dynamicToUint8List(privateKey));
    return wallet;
  }

  @override
  Future<Uint8List> mnemonicToPrivateKey(String mnemonic) async {
    Uint8List seed;
    if (mnemonic.split(' ').length == 28 || mnemonic.split(' ').length == 29) {
      seed = generateFromMnemonic(mnemonic);
      final blake2b = Blake2b();
      blake2b.update(seed, 0, seed.length);
      blake2b.update(SC_INDEX, 0, SC_INDEX.length);
      return blake2b.doFinal();
    } else {
      seed = HDWallet.mnemonicToEntropy(mnemonic);
      final hash = Blake2b.getBlake2bHash(seed);
      final blake2b = Blake2b();
      blake2b.update(hash, 0, hash.length);
      blake2b.update(SC_INDEX, 0, SC_INDEX.length);
      return blake2b.doFinal();
    }
  }

  @override
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    return ED25519.privateKeyToPublicKey(privateKey);
  }

  @override
  String publicKeyToAddress(Uint8List publicKey) {
    final Algorithm = 'ed25519';
    final buf = List<int>.filled(65, 0);
    for (var i = 0; i < Algorithm.length; i++) {
      buf[i + 1] = Algorithm.codeUnitAt(i);
    }
    buf[17] = publicKey.length;
    for (var i = 0; i < publicKey.length; i++) {
      buf[i + 25] = publicKey[i];
    }

    final pubkeyHash =
        Blake2b.getBlake2bHash(Uint8List.fromList(buf.sublist(0, 57)));
    final timeLockHash = dynamicToUint8List(TIME_LOCK_HASH);
    final sigHash = dynamicToUint8List(SIG_HASH);

    buf[0] = 0x01;
    for (var i = 0; i < timeLockHash.length; i++) {
      buf[i + 1] = timeLockHash[i];
    }
    for (var i = 0; i < pubkeyHash.length; i++) {
      buf[i + 33] = pubkeyHash[i];
    }
    final tlpkHash = Blake2b.getBlake2bHash(Uint8List.fromList(buf));
    for (var i = 0; i < tlpkHash.length; i++) {
      buf[i + 1] = tlpkHash[i];
    }
    for (var i = 0; i < sigHash.length; i++) {
      buf[i + 33] = sigHash[i];
    }

    final unlockHash = Blake2b.getBlake2bHash(Uint8List.fromList(buf));
    final checksum = Blake2b.getBlake2bHash(Uint8List.fromList(unlockHash));
    final address = unlockHash + checksum.sublist(0, 6);
    return dynamicToString(address);
  }

  /// return base64 signature
  @override
  String sign(String message) {
    final signature = ED25519.sign(privateKey, message);
    return base64.encode(signature);
  }

  /// signature should be base64
  @override
  bool verify(String signedMessage, String message) {
    return ED25519.verify(publicKey, base64.decode(signedMessage), message);
  }

  /// generate private key from [mnemonic], support 28 or 29 words.
  /// 
  /// @param mnemonic
  static Uint8List generateFromMnemonic(mnemonic) {
    final intEntropy = phraseToInt(mnemonic);
    return intToBytes(intEntropy).sublist(0, 32).toUint8List();
  }
}
