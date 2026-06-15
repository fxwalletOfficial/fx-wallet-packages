import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/gen/keystone/base.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/transaction.pb.dart';
import 'package:test/test.dart';

void main() {
  group('BchSignRequestUR', () {
    test('keeps BCH as the default Keystone UTXO coin code', () {
      final ur = _buildRequest();
      final signTx = _decodeSignTransaction(ur);

      expect(signTx.coinCode, 'BCH');
      expect(signTx.decimal, 8);
      expect(signTx.whichTransaction(), SignTransaction_Transaction.bchTx);
    });

    test('builds Keystone DOGE request with DOGE coin code', () {
      final ur = _buildRequest(coinCode: 'DOGE');
      final signTx = _decodeSignTransaction(ur);

      expect(ur.type, RegistryType.KEYSTONE_SIGN_REQUEST.type);
      expect(signTx.coinCode, 'DOGE');
      expect(signTx.hdPath, "m/44'/3'/0'/0/0");
      expect(signTx.decimal, 8);
      expect(signTx.whichTransaction(), SignTransaction_Transaction.bchTx);
      expect(signTx.bchTx.inputs.single.ownerKeyPath, "m/44'/3'/0'/0/0");
      expect(signTx.bchTx.outputs.single.address, 'D8Bq7z8rJbJ6z8G4m7Zx8Q9x2n3P4q5R6S');
    });
  });
}

BchSignRequestUR _buildRequest({String coinCode = 'BCH'}) {
  return BchSignRequestUR.fromTransaction(
    inputs: [
      BchInput(
        hash: '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff',
        index: 1,
        value: 100000000,
        pubkey: '03019967bdd2d94ee29f00fb77eb57064afb1c56fcc7d1fdfd0ae9c9c6d65128bd',
        ownerKeyPath: "m/44'/3'/0'/0/0",
      ),
    ],
    outputs: [
      BchOutput(
        address: 'D8Bq7z8rJbJ6z8G4m7Zx8Q9x2n3P4q5R6S',
        value: 99900000,
      ),
    ],
    fee: 100000,
    xfp: 'd4d0b746',
    hdPath: "m/44'/3'/0'/0/0",
    requestId: 'doge-request-id',
    origin: 'FxWallet',
    coinCode: coinCode,
  );
}

SignTransaction _decodeSignTransaction(UR ur) {
  final data = ur.decodeCBOR() as CborMap;
  final signDataBytes = Uint8List.fromList(
    (data[CborSmallInt(1)] as CborBytes).bytes,
  );
  final base = Base.fromBuffer(GZipCodec().decode(signDataBytes));
  return base.payloadData.signTx;
}
