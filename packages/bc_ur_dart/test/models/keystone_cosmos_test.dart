import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:test/test.dart';

void main() {
  const testPath = "m/44'/118'/0'/0/0";
  const secondaryPath = "m/44'/118'/1'/0/0";
  const testXfp = 'abcd1234';
  const secondaryXfp = '1234abcd';
  const testAminoHex = '7b22636861696e5f6964223a22636f736d6f736875622d34227d';
  const testDirectHex = '0a0a0a080a02107b12021234';
  const testOrigin = 'FxWallet';
  const testAddress = 'cosmos1qnk2n4nlkpw9xfqntladh74er2xa62wgas5vdz';
  const secondaryAddress = 'cosmos1p8h4n2m6y5u7n8k9s0v3z4x5c6b7d8e9f0g1h2';
  final testSignature = Uint8List.fromList(List.generate(64, (index) => index));
  final testPublicKey = Uint8List.fromList([0x02, ...List.generate(32, (index) => index)]);

  group('GoldShell CosmosSignRequest', () {
    test('generateSignRequest remains unchanged', () {
      final ur = CosmosSignRequest.generateSignRequest(
        signData: testAminoHex,
        path: testPath,
        chain: 'cosmos',
        xfp: testXfp,
        origin: testOrigin,
        fee: 2500,
      );

      final decoded = CosmosSignRequest.fromCBOR(ur.payload);
      expect(decoded.chain, equals('cosmos'));
      expect(decoded.origin, equals(testOrigin));
      expect(decoded.fee, equals(2500));
      expect(decoded.derivationPath.getPath(), equals(testPath));
    });
  });

  group('KeystoneCosmosSignRequest', () {
    test('buildAminoRequest encodes official single-path payload', () {
      final ur = KeystoneCosmosSignRequest.buildAminoRequest(
        signDataHex: testAminoHex,
        path: testPath,
        xfp: testXfp,
        address: testAddress,
        origin: testOrigin,
      );

      final decoded = KeystoneCosmosSignRequest.fromUR(ur);
      expect(decoded.dataType, equals(CosmosDataType.amino));
      expect(decoded.getDerivationPaths(), equals([testPath]));
      expect(decoded.addresses, equals([testAddress]));
      expect(decoded.origin, equals(testOrigin));
    });

    test('buildDirectRequest uses direct data type', () {
      final ur = KeystoneCosmosSignRequest.buildDirectRequest(
        signDataHex: testDirectHex,
        path: testPath,
        xfp: testXfp,
        origin: testOrigin,
      );

      final decoded = KeystoneCosmosSignRequest.fromUR(ur);
      expect(decoded.dataType, equals(CosmosDataType.direct));
      expect(decoded.addresses, isNull);
    });

    test('buildTextualRequest uses textual data type', () {
      final ur = KeystoneCosmosSignRequest.buildTextualRequest(
        signDataHex: testAminoHex,
        path: testPath,
        xfp: testXfp,
      );

      final decoded = KeystoneCosmosSignRequest.fromUR(ur);
      expect(decoded.dataType, equals(CosmosDataType.textual));
    });

    test('buildMessageRequest uses message data type', () {
      final ur = KeystoneCosmosSignRequest.buildMessageRequest(
        signDataHex: testAminoHex,
        path: testPath,
        xfp: testXfp,
      );

      final decoded = KeystoneCosmosSignRequest.fromUR(ur);
      expect(decoded.dataType, equals(CosmosDataType.message));
    });

    test('constructCosmosRequest supports multiple derivation paths and addresses', () {
      final ur = KeystoneCosmosSignRequest.constructCosmosRequest(
        signDataHex: testAminoHex,
        dataType: CosmosDataType.direct,
        paths: [testPath, secondaryPath],
        xfps: [testXfp, secondaryXfp],
        addresses: [testAddress, secondaryAddress],
        origin: testOrigin,
      );

      final decoded = KeystoneCosmosSignRequest.fromUR(ur);
      expect(decoded.dataType, equals(CosmosDataType.direct));
      expect(decoded.getDerivationPaths(), equals([testPath, secondaryPath]));
      expect(decoded.addresses, equals([testAddress, secondaryAddress]));
      expect(decoded.origin, equals(testOrigin));
      expect(decoded.getSourceFingerprints().length, equals(2));
      expect(decoded.getSourceFingerprints().first, equals(fromHex(testXfp)));
      expect(decoded.getSourceFingerprints().last, equals(fromHex(secondaryXfp)));
    });

    test('CBOR key 3 is int and key 4 is a list of keypaths', () {
      final ur = KeystoneCosmosSignRequest.buildAminoRequest(
        signDataHex: testAminoHex,
        path: testPath,
        xfp: testXfp,
        address: testAddress,
      );

      final cborMap = cbor.decode(ur.payload) as CborMap;
      final key3 = cborMap[CborSmallInt(3)];
      final key4 = cborMap[CborSmallInt(4)];

      expect(key3, isA<CborInt>());
      expect((key3 as CborInt).toInt(), equals(CosmosDataType.amino.index));
      expect(key4, isA<CborList>());

      final derivationPaths = (key4 as CborList).toList();
      expect(derivationPaths, hasLength(1));
      expect(derivationPaths.first, isA<CborMap>());
    });

    test('constructCosmosRequest validates list lengths', () {
      expect(
        () => KeystoneCosmosSignRequest.constructCosmosRequest(
          signDataHex: testAminoHex,
          dataType: CosmosDataType.amino,
          paths: [testPath],
          xfps: [testXfp, secondaryXfp],
        ),
        throwsArgumentError,
      );

      expect(
        () => KeystoneCosmosSignRequest.constructCosmosRequest(
          signDataHex: testAminoHex,
          dataType: CosmosDataType.amino,
          paths: [testPath],
          xfps: [testXfp],
          addresses: [testAddress, secondaryAddress],
        ),
        throwsArgumentError,
      );
    });

    test('fromUR rejects wrong UR type', () {
      final wrongTypeUR = UR(type: 'eth-sign-request', payload: Uint8List(10));
      expect(
        () => KeystoneCosmosSignRequest.fromUR(wrongTypeUR),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            contains('Invalid UR type'),
          ),
        ),
      );
    });
  });

  group('GoldShell and Keystone payloads coexist', () {
    test('same UR type but different payload shapes', () {
      final goldshellUR = CosmosSignRequest.generateSignRequest(
        signData: testAminoHex,
        path: testPath,
        chain: 'cosmos',
        xfp: testXfp,
      );

      final keystoneUR = KeystoneCosmosSignRequest.buildAminoRequest(
        signDataHex: testAminoHex,
        path: testPath,
        xfp: testXfp,
      );

      expect(goldshellUR.type, equals(keystoneUR.type));
      expect(goldshellUR.payload, isNot(equals(keystoneUR.payload)));
    });
  });

  group('KeystoneCosmosSignature', () {
    test('fromSignature builds official Keystone signature payload', () {
      final request = KeystoneCosmosSignRequest.buildDirectRequest(
        signDataHex: testDirectHex,
        path: testPath,
        xfp: testXfp,
        address: testAddress,
        origin: testOrigin,
      );

      final decodedRequest = KeystoneCosmosSignRequest.fromUR(request);
      final responseUR = KeystoneCosmosSignature.fromSignature(
        request: decodedRequest,
        signature: testSignature,
        publicKey: testPublicKey,
      );

      expect(responseUR.type, equals('cosmos-signature'));

      final decodedResponse = KeystoneCosmosSignature.fromCBOR(responseUR.payload);
      expect(decodedResponse.getRequestId(), equals(decodedRequest.getRequestId()));
      expect(decodedResponse.getSignature(), equals(testSignature));
      expect(decodedResponse.getPublicKey(), equals(testPublicKey));
    });

    test('CBOR key 1/2/3 map to requestId/signature/publicKey', () {
      final item = KeystoneCosmosSignature(
        requestId: Uint8List.fromList(List.generate(16, (index) => index)),
        signature: testSignature,
        publicKey: testPublicKey,
      );

      final cborMap = item.toCborValue() as CborMap;

      expect(cborMap[CborSmallInt(1)], isA<CborBytes>());
      expect((cborMap[CborSmallInt(1)] as CborBytes).tags, contains(RegistryType.UUID.tag));
      expect(cborMap[CborSmallInt(2)], isA<CborBytes>());
      expect(cborMap[CborSmallInt(3)], isA<CborBytes>());
    });

    test('Keystone and GoldShell cosmos-signature payloads coexist', () {
      final goldshellRequest = CosmosSignRequest(
        signData: Uint8List(32),
        chain: 'cosmos',
        derivationPath: CryptoKeypath(),
        origin: testOrigin,
      );
      final goldshellUR = CosmosSignature.fromSignature(
        request: goldshellRequest,
        signature: testSignature,
      );

      final keystoneRequest = KeystoneCosmosSignRequest.buildAminoRequest(
        signDataHex: testAminoHex,
        path: testPath,
        xfp: testXfp,
        address: testAddress,
      );
      final keystoneUR = KeystoneCosmosSignature.fromSignature(
        request: KeystoneCosmosSignRequest.fromUR(keystoneRequest),
        signature: testSignature,
        publicKey: testPublicKey,
      );

      expect(goldshellUR.type, equals(keystoneUR.type));
      expect(goldshellUR.payload, isNot(equals(keystoneUR.payload)));
    });
  });
}
