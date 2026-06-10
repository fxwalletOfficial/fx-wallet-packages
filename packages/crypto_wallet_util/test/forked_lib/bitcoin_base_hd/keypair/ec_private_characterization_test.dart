import 'package:test/test.dart';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_base_hd/src/crypto/keypair/ec_private.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_base_hd/src/bitcoin/script/script.dart';

/// Characterization tests for ECPrivate signing (bitcoin_base_hd fork).
///
/// 背景：BTC/LTC/BCH 钱包的 sign() 走 ECPrivate.signInput / signTapRoot，但
/// 各币种 WalletType.verify 目前是 `return true` 桩实现，wallet_test 的 sign+verify
/// 并未对签名输出做 golden 比对。而 blockchain_utils 1.x→6.x 升级重写了这些方法体
/// (BitcoinSigner→BitcoinKeySigner: signTransaction→signECDSADerConst,
///  signSchnorrTransaction→signBip340Const+P2TRUtils.calculateTweek,
///  signMessage→signMessageConst().sublist(1))。
///
/// 下列 golden 采自升级前(blockchain_utils 1.6.0)并经升级前后逐字节比对确认一致，
/// 用以锁定这条活跃签名路径，防止后续改动产生回归。
void main() {
  final priv = BytesUtils.fromHexString(
    '3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1',
  );
  final digest = BytesUtils.fromHexString(
    'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
  );

  group('ECPrivate signing (pins pre-upgrade bytes)', () {
    test('signInput (ECDSA DER + sighash)', () {
      expect(
        ECPrivate.fromBytes(priv).signInput(digest),
        '30440220547b70c9e3862a339fa6c0aed6c6cb86df4a202e87f6bd33082ebdb5bfc'
        '9049f02200f366449e8ffd33be92676634a716b2077027b11dc76b33ecae62a6ddf'
        'fe21e201',
      );
    });

    test('signTapRoot (key-path, tweak=true)', () {
      expect(
        ECPrivate.fromBytes(priv).signTapRoot(digest),
        '603892c5f393edb586604f09d91b944ab6a62f7991c14c98af0a319674dd1459c1'
        'af08f3b8a648442e893166d47a208a716d697a415179fb49f3d4b23d557fb4',
      );
    });

    test('signMessage (compact, recovery byte stripped)', () {
      expect(
        ECPrivate.fromBytes(priv).signMessage(digest),
        '561fe99047a805b001da87f8730291706eddb48aa2b2a6d80f129cc95a04eae53b'
        '0d637c3057d0a3eab2bdec5cca058651b9fa100dc5d1c8e177fca9976a9c34',
      );
    });

    // signTapRoot must fold a committed Taproot script tree's Merkle root into
    // the key-path tweak — otherwise a key-path spend of a script-tree address
    // is signed with the wrong tweak and is invalid (funds could be unspendable).
    test('signTapRoot with script tree folds Merkle root into the tweak', () {
      final pk = ECPrivate.fromBytes(priv);
      final leaf = Script(script: ['OP_1']);
      final withTree = pk.signTapRoot(digest, tapScripts: [
        [leaf]
      ]);

      // The script tree must change the tweak → different from plain key-path.
      expect(withTree, isNot(pk.signTapRoot(digest)));
      expect(
        withTree,
        '252029cd4fb0a25a66283d371993085cfb17dbd814bbef6cc744c04ac84d5ce6'
        '8bb24ba90b1b61a6d92fa3b6a2b33420976d8765b726136c030b145c94d9883c',
      );

      // And it must verify against the script-tree-tweaked output key.
      final pubPoint = pk.getPublic().publicKey.point as ProjectiveECCPoint;
      final tweak = P2TRUtils.calculateTweek(pubPoint, script: [leaf.toBytes()]);
      expect(
        BitcoinSignatureVerifier.fromKeyBytes(pk.getPublic().toBytes())
            .verifyBip340Signature(
                digest: digest,
                signature: BytesUtils.fromHexString(withTree),
                tapTweakHash: tweak),
        isTrue,
      );
    });
  });
}
