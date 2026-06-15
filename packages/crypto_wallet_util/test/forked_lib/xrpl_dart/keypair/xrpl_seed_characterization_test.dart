import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/keypair/xrpl_private_key.dart';

/// Characterization tests for the XRPL *family-seed* key derivation.
///
/// 背景：crypto_wallet_util 的 XrpCoin 走 bip32 + XRPPrivateKey.fromHex，
/// 不经过这里的 family-seed 派生(deriveKeyPair / deriveED25519 / decodeSeed)。
/// 因此这条路径运行时 0% 覆盖——而 blockchain_utils 1.x→6.x 升级恰好要改动它：
///   * deriveKeyPair 里的 `BigintUtils.orderLen(order)` (6.x 已移除/改名)
///   * deriveED25519 里 `sha512HashHalves(seed).item1` (6.x 改为 record .$1)
///   * decodeSeed 返回的 `Tuple` (6.x 改为 record)
///   * `bytesEqual` / `Secp256k1PrivateKeyEcdsa` 等改名
///
/// 这些 golden 值采自升级前(blockchain_utils 1.6.0)，并用 XRPL 官方主种子
/// 向量交叉验证(snoPBrXtMeMyMHUVTgbuqAfg1SUTb → rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh)，
/// 确保升级后这些字节逐一不变。任何漂移都会让本测试失败。
void main() {
  group('XRPL family-seed derivation (pins pre-upgrade behavior)', () {
    // ---- secp256k1：覆盖 orderLen / deriveKeyPair / _getSecret ----
    test('secp256k1 fromSeed (canonical XRPL master seed)', () {
      const masterSeed = 'snoPBrXtMeMyMHUVTgbuqAfg1SUTb';
      final pk = XRPPrivateKey.fromSeed(masterSeed);
      final pub = pk.getPublic();

      expect(pk.algorithm.prefix, 0x00, reason: 'secp256k1 prefix');
      expect(pk.toHex(),
          '001ACAAEDECE405B2A958212629E16F2EB46B153EEE94CDD350FDEFF52795525B7');
      expect(pub.toHex(),
          '0330E7FC9D56BB25D6893BA3F317AE5BCF33B3291BD63DB32654A313222F7FD020');
      // XRPL 官方已知向量，交叉验证派生正确性
      expect(pub.toAddress().toString(), 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh');
    });

    test('secp256k1 fromEntropy (== decoded master seed entropy)', () {
      const entropyHex = 'DEDCE9CE67B451D852FD4E846FCDE31C';
      final pk = XRPPrivateKey.fromEntropy(entropyHex,
          algorithm: XRPKeyAlgorithm.secp256k1);

      expect(pk.toHex(),
          '001ACAAEDECE405B2A958212629E16F2EB46B153EEE94CDD350FDEFF52795525B7');
      expect(pk.getPublic().toAddress().toString(),
          'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh');
    });

    // ---- ed25519：覆盖 deriveED25519 的 sha512HashHalves().item1 ----
    test('ed25519 fromEntropy', () {
      const entropyHex = '4C3A1D213FBDFB14C056C8B6E6E07A4C';
      final pk = XRPPrivateKey.fromEntropy(entropyHex,
          algorithm: XRPKeyAlgorithm.ed25519);

      expect(pk.algorithm.prefix, 0xED, reason: 'ed25519 prefix');
      expect(pk.toHex(),
          'ED20737253887BDBECD50DE917352142D4A1E1BDF034EC9AF9EEF5FC228FCB0E0A');
      expect(pk.getPublic().toAddress().toString(),
          'rhW2hRNo2sz4HfgYspzrwgeSiMi59HaQ87');
    });

    // ---- 签名往返：覆盖 secp256k1 sign + 公钥验签(活路径再加一层保险) ----
    test('secp256k1 sign & verify round-trip', () {
      final pk = XRPPrivateKey.fromSeed('snoPBrXtMeMyMHUVTgbuqAfg1SUTb');
      const message = 'deadbeefdeadbeefdeadbeefdeadbeef';
      final sig = pk.sign(message);
      expect(sig, isNotEmpty);
      expect(pk.getPublic().verifySignature(message, sig), isTrue);
    });
  });
}
