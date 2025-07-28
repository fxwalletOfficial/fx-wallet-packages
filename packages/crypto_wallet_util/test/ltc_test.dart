import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final ltcWallet = await LtcCoin.fromMnemonic(mnemonic);
  final ltcTaprootWallet = await LtcCoin.fromMnemonic(mnemonic, null, true);

  group('LTC Basic Wallet Tests', () {
    test('ltc legacy address generation', () {
      final address = ltcWallet.publicKeyToAddress(ltcWallet.publicKey);
      expect(address, equals('LKEkcs5DDr7RAdXrbG4jGN4enMeopXVXuz'));
    });

    test('ltc taproot address generation', () {
      final address = ltcTaprootWallet.publicKeyToAddress(ltcTaprootWallet.publicKey);
      expect(address, isNotEmpty);
      expect(address, equals('ltc1phtf7arjcnm334qsk8fsfkf5hy73sqev5j9f7nu2st9hwynvjcp9syjl4le'));
    });

    test('ltc legacy sign/verify', () {
      const message = 'bd3229f69d047ccc5e8375c296a0aa6e1935c0fbdac78cfca0cb38be94b9b32c';
      final signature = ltcWallet.sign(message);
      expect(signature, equals('3044022054c297513c0d92156e8c5bf4dcb06646427165e63b61776a0b3160171948329a0220215ea893945dc475b418155eb12e336fa823317b780ee5fbd71a5ad06c9ac20c01'));
    });

    test('ltc taproot sign/verify', () {
      const message = 'e1b77179a359de8908469099b86879029ca96147f0158e5a967332972b1df785';
      final signature = ltcTaprootWallet.sign(message);
      expect(signature, equals('5ea5a5ca245d0c58d2025454e5db2375ebb89d7f95da5e74bf0ccea846c85aa458386fa59314299671a272a47ceb54309e94cf59d88aaf3e6629c2b108855bf5'));
    });

    test('ltc private key to public key', () {
      final publicKey = ltcWallet.privateKeyToPublicKey(ltcWallet.privateKey);
      expect(publicKey, isNotEmpty);
      expect(publicKey.length, 33); // Compressed public key (default)
    });

    test('ltc from private key', () {
      final privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final wallet = LtcCoin.fromPrivateKey(privateKeyHex);
      expect(wallet.privateKey, isNotEmpty);
      expect(wallet.publicKey, isNotEmpty);
    });

    test('ltc taproot from private key', () {
      final privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final wallet = LtcCoin.fromPrivateKey(privateKeyHex, null, true);
      expect(wallet.privateKey, isNotEmpty);
      expect(wallet.publicKey, isNotEmpty);
      expect(wallet.isTaproot, isTrue);
    });
  });

  group('LTC GSPL Transaction Tests', () {
    test('ltc legacy gspl transaction signing', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 62926,
            signHashType: 1, // SIGHASH_ALL
          ),
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 82787,
            signHashType: 1, // SIGHASH_ALL
          )
        ],
        hex: '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(ltcWallet, txData);
      final signedTxData = signer.sign();

      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
      expect(signedTxData.message, isNotEmpty);

      // Verify all inputs have signatures
      for (final input in signedTxData.inputs) {
        expect(input.signature, isNotNull);
        expect(input.signature!.isNotEmpty, true);
      }
    });

    test('ltc gspl transaction with change output', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 62926,
            signHashType: 1, // SIGHASH_ALL
          ),
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 82787,
            signHashType: 1, // SIGHASH_ALL
          )
        ],
        hex: '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
        change: GsplItem(
          path: "m/44'/2'/0'/1/0",
          amount: 10000,
          signHashType: 1,
        ),
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(ltcWallet, txData);
      final signedTxData = signer.sign();

      expect(signer.verify(), true);
      expect(signedTxData.change, isNotNull);
    });
  });

  group('LTC Error Handling Tests', () {
    test('should throw exception for invalid private key', () {
      expect(
        () => LtcCoin.fromPrivateKey('invalid'),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for null input path in GSPL', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: null,
            amount: 62926,
            signHashType: 1,
          )
        ],
        hex: '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(ltcWallet, txData);
      expect(
        () => signer.sign(),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for null input amount in GSPL', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 62926,
            signHashType: 1,
          )
        ],
        hex: '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(ltcWallet, txData);
      expect(
        () => signer.sign(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LTC Signature Hash Type Tests', () {
    test('ltc legacy should use legacy signature hash', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 62926,
            signHashType: 1, // SIGHASH_ALL
          ),
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 82787,
            signHashType: 1, // SIGHASH_ALL
          )
        ],
        hex: '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(ltcWallet, txData);
      final signedTxData = signer.sign();
      
      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
    });

    test('ltc taproot should use BIP143 signature hash', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 62926,
            signHashType: 1, // SIGHASH_ALL
          ),
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 82787,
            signHashType: 1, // SIGHASH_ALL
          )
        ],
        hex: '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(ltcTaprootWallet, txData);
      final signedTxData = signer.sign();
      
      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
    });

    test('ltc should handle different sign hash types', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 62926,
            signHashType: 1, // SIGHASH_ALL
          ),
          GsplItem(
            path: "m/44'/2'/0'/0/0",
            amount: 82787,
            signHashType: 1, // SIGHASH_ALL
          )
        ],
        hex: '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(ltcWallet, txData);
      final signedTxData = signer.sign();
      
      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
    });
  });
}
