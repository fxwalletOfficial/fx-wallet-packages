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
    // print(Converter.bytesToHex(uint8List));

    test('String', () {
      for (final value in data) {
        String result = dynamicToString(value);
        expect(result, string);
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
        "0216a68dad4794ade6d2f28eeda7c00a5fd70851ec09157545f5f0f6d788209ba1";
    final exceptedUncompressedPublicKey =
        "0416a68dad4794ade6d2f28eeda7c00a5fd70851ec09157545f5f0f6d788209ba1bb5d763fdec478da7974a7dd02187dd8a096f52b6ecac934aae0af4c2af444f6";

    final uncompressedPublicKey =
        EcdaSignature.decompressPublicKey(publicKey.toUint8List()).toStr();

    expect(uncompressedPublicKey, exceptedUncompressedPublicKey);
  });
}
