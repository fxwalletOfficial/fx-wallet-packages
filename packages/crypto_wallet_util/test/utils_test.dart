import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/crypto_utils.dart';

void main() {
  group('dynamic to', () {
    String hexStr = '0x123456';
    String string = '123456';
    List<int> list = [18, 52, 86];
    Uint8List uint8List = Uint8List.fromList(list);
    List<dynamic> data = [hexStr, string, list, uint8List];
    int error_type = 1;
    BigInt bigInt = BigInt.from(123456);
    // print(Converter.bytesToHex(uint8List));

    test('String', () {
      for (final value in data) {
        String result = dynamicToString(value);
        expect(result, string);
        expect(result.toStr(), string);
      }
      try {
        dynamicToString(error_type);
      } catch (error) {
        assert(error
            .toString()
            .contains('value must be String, List<int> or Uint8List'));
      }
    });

    test('hex', () {
      for (final value in data) {
        String result = dynamicToHex(value);
        expect(result, hexStr);
        expect(list.toHex(), hexStr);
      }
      try {
        dynamicToHex(error_type);
      } catch (error) {
        assert(error
            .toString()
            .contains('value must be String, List<int> or Uint8List'));
      }
    });

    test('Uint8List', () {
      for (final value in data) {
        Uint8List result = dynamicToUint8List(value);
        expect(result, uint8List);
      }
      try {
        dynamicToUint8List(error_type);
      } catch (error) {
        assert(error
            .toString()
            .contains('value must be String, List<int> or Uint8List'));
      }
    });

    test('bigint', () {
      final length = bigInt.byteLength;
      expect(length, 3);
      expect(bigInt.toUint8List().length, 3);
    });
  });

  group('check address', () {
    test('fil', () {
      const address = 'f410fnoxwr77ghbwugw5g2jjstezrezhbi62cdqsv4ua';
      final walletSetting = FILChain().mainnet;
      assert(AddressUtils.checkAddressValid(address, walletSetting));
    });
  });

  test('decompressed publicKey', () {
    final publicKey =
        '0216a68dad4794ade6d2f28eeda7c00a5fd70851ec09157545f5f0f6d788209ba1';
    final exceptedUncompressedPublicKey =
        '0416a68dad4794ade6d2f28eeda7c00a5fd70851ec09157545f5f0f6d788209ba1bb5d763fdec478da7974a7dd02187dd8a096f52b6ecac934aae0af4c2af444f6';

    final uncompressedPublicKey =
        EcdaSignature.decompressPublicKey(publicKey.toUint8List()).toStr();

    expect(uncompressedPublicKey, exceptedUncompressedPublicKey);
  });

  test('bigint utils', () {
    final bn = u8aToBn(Uint8List.fromList([1, 2, 3]));
    final u8a = bnToU8a(bn);
    expect(u8a, Uint8List.fromList([1, 2, 3]));
  });

  test('hex', () {
    // final bnZero = ;
    expect(hexToBn(null), BigInt.from(0));
    expect(hexToBn('12'), BigInt.from(18));
    expect(hexToBn(12), BigInt.from(12));
    expect(
        hexToBn(12, endian: Endian.little, isNegative: true), BigInt.from(12));
    expect(hexToBn('0x12', endian: Endian.little, isNegative: true),
        BigInt.from(18));
  });

  test('digest', () {
    const hex = '0x123456';
    const data = '0x123456';
    expect(sha256FromUTF8(data),
        '042ff1f3adaa07b6ee123d3c96425da80c35124dfc2f2a74e39b6d8dea7b7816');
    expect(hmacSha512(data, hex).toHex(),
        '0x565255625b7d1c1d8dff051933a28eb0aa595f33cee70f25fb2653162e8e8e283a6de839616fe107812f515248538c39e8ab83b808946f37fe57e28b87ede6b1');
    expect(hmacSha512FromList(data.toUint8List(), hex.toUint8List()).toHex(),
        '0xd990f12014c6852dfa852f60a3673c055021e46ab0d4e3d01defe6a6c2534b1542cefd67abb4e70babf43e3e9dce91bba9db86837e52b39d26ee83d612c5465a');
    expect(sha160fromHex(hex).toHex(),
        '0x52370c1a4283871db94dcd77cfd34eb47b917123');
  });

  test('number', () {
    expect(NumberUtil.toSafeDoubleString('123456'), '123456');
    expect(NumberUtil.toFixedDouble(value: '123456', decimal: 18), 123456.0);
    expect(NumberUtil.numberPowToInt(value: 1, pow: 18), 1000000000000000000);
    expect(NumberUtil.toDouble('123456'), 123456.0);
  });

  test("hd wallet", () {
    const mnemonic =
        'few tag video grain jealous light tired vapor shed festival shine tag';
    const path = "m/44'/60'/0'/0/0";
    final seed = HDWallet.mnemonicToSeed(mnemonic);
    final signer = HDWallet.getBip32Signer(mnemonic, path);
    final hdLedger = HDWallet.hdLedger(mnemonic, path);
    expect(signer.privateKey!.toHex(),
        "0x85d7e7a29d83ed589e0b0feba5018b789b580456281be5a01abebd72e232e251");
    expect(hdLedger.toHex(),
        "0x98a75c7bad3c51a8d77c076e070b6c0c1f15468d6de8bc53633a6894fc320241");

    final eip25519Signer = HDLedger.ledgerMaster(seed, path);
    expect(eip25519Signer.toHex(),
        "0x98a75c7bad3c51a8d77c076e070b6c0c1f15468d6de8bc53633a6894fc320241");
  });

  group('EthMessageSigner', () {
    // Test private key and corresponding public key
    final Uint8List testPrivateKey = Uint8List.fromList([
      0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
      0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10,
      0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
      0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10
    ]);

    test('ethereumMessageHash should generate correct hash', () {
      const message = 'Hello, Ethereum!';
      final hash = EthMessageSigner.ethereumMessageHash(message);
      
      expect(hash, isA<Uint8List>());
      expect(hash.length, 32); // Keccak-256 produces 32-byte hash
      
      // Verify hash is not empty
      expect(hash.any((byte) => byte != 0), isTrue);
    });

    test('ethereumMessageHash should be deterministic', () {
      const message = 'Test message';
      final hash1 = EthMessageSigner.ethereumMessageHash(message);
      final hash2 = EthMessageSigner.ethereumMessageHash(message);
      
      expect(hash1, equals(hash2));
    });

    test('ethereumMessageHash should handle empty message', () {
      const message = '';
      final hash = EthMessageSigner.ethereumMessageHash(message);
      
      expect(hash, isA<Uint8List>());
      expect(hash.length, 32);
    });

    test('ethereumMessageHash should handle unicode characters', () {
      const message = 'Hello 世界! 🚀';
      final hash = EthMessageSigner.ethereumMessageHash(message);
      
      expect(hash, isA<Uint8List>());
      expect(hash.length, 32);
    });

    test('signMessage should generate valid signature', () {
      const message = 'Test message for signing';
      final signature = EthMessageSigner.signMessage(message, testPrivateKey);
      
      expect(signature, isA<String>());
      expect(signature.length, 132); // 0x + 130 hex chars (r+s+v)
      expect(signature.startsWith('0x'), isTrue); // Has 0x prefix
      
      // Verify signature format (hexadecimal with 0x prefix)
      final hexPattern = RegExp(r'^0x[0-9a-fA-F]{130}$');
      expect(hexPattern.hasMatch(signature), isTrue);
    });

    test('signMessage should be deterministic for same input', () {
      const message = 'Deterministic test';
      final signature1 = EthMessageSigner.signMessage(message, testPrivateKey);
      final signature2 = EthMessageSigner.signMessage(message, testPrivateKey);
      
      expect(signature1, equals(signature2));
    });

    test('signMessage should generate different signatures for different messages', () {
      const message1 = 'Message 1';
      const message2 = 'Message 2';
      final signature1 = EthMessageSigner.signMessage(message1, testPrivateKey);
      final signature2 = EthMessageSigner.signMessage(message2, testPrivateKey);
      
      expect(signature1, isNot(equals(signature2)));
    });

    test('verifyMessage should verify valid signature', () {
      const message = 'Message to verify';
      final signature = EthMessageSigner.signMessage(message, testPrivateKey);
      
      // Get public key from private key - use getUnCompressedPublicKey for correct format
      final publicKey = EcdaSignature.getUnCompressedPublicKey(testPrivateKey);
      
      final isValid = EthMessageSigner.verifyMessage(message, signature, publicKey);
      expect(isValid, isTrue);
    });

    test('verifyMessage should reject invalid signature', () {
      const message = 'Message to verify';
      final invalidSignature = '0x' + '1' * 130; // Invalid signature (0x + 130 hex chars)
      
      // Get public key from private key - use getUnCompressedPublicKey for correct format
      final publicKey = EcdaSignature.getUnCompressedPublicKey(testPrivateKey);
      
      final isValid = EthMessageSigner.verifyMessage(message, invalidSignature, publicKey);
      expect(isValid, isFalse);
    });

    test('verifyMessage should reject signature with wrong message', () {
      const message1 = 'Original message';
      const message2 = 'Different message';
      final signature = EthMessageSigner.signMessage(message1, testPrivateKey);
      
      // Get public key from private key - use getUnCompressedPublicKey for correct format
      final publicKey = EcdaSignature.getUnCompressedPublicKey(testPrivateKey);
      
      final isValid = EthMessageSigner.verifyMessage(message2, signature, publicKey);
      expect(isValid, isFalse);
    });

    test('verifyMessage should throw error for invalid signature length', () {
      const message = 'Test message';
      const invalidSignature = '0x123'; // Too short (should be 0x + 130 hex chars)
      
      // Get public key from private key - use getUnCompressedPublicKey for correct format
      final publicKey = EcdaSignature.getUnCompressedPublicKey(testPrivateKey);
      
      expect(
        () => EthMessageSigner.verifyMessage(message, invalidSignature, publicKey),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('verifyMessage should throw error for signature without 0x prefix', () {
      const message = 'Test message';
      final invalidSignature = '1' * 130; // Missing 0x prefix (should be 0x + 130 hex chars)
      
      // Get public key from private key - use getUnCompressedPublicKey for correct format
      final publicKey = EcdaSignature.getUnCompressedPublicKey(testPrivateKey);
      
      expect(
        () => EthMessageSigner.verifyMessage(message, invalidSignature, publicKey),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('end-to-end message signing and verification', () {
      const message = 'Complete end-to-end test message';
      
      // Sign the message
      final signature = EthMessageSigner.signMessage(message, testPrivateKey);
      expect(signature, isA<String>());
      expect(signature.length, 132); // 0x + 130 hex chars (r+s+v)
      
      // Get public key - use getUnCompressedPublicKey for correct format
      final publicKey = EcdaSignature.getUnCompressedPublicKey(testPrivateKey);
      
      // Verify the signature
      final isValid = EthMessageSigner.verifyMessage(message, signature, publicKey);
      expect(isValid, isTrue);
      
      // Verify with wrong message should fail
      final isValidWrongMessage = EthMessageSigner.verifyMessage('Wrong message', signature, publicKey);
      expect(isValidWrongMessage, isFalse);
    });
  });
}
