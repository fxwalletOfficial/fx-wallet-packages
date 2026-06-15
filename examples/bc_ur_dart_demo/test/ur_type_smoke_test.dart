import 'package:bc_ur_dart_example/common/mock_data.dart';
import 'package:bc_ur_dart_example/encode/type_config.dart';
import 'package:bc_ur_dart_example/encode/ur_encoder.dart';
import 'package:bc_ur_dart_example/scan/ur_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crypto hdkey mock mirrors a crypto multi accounts chain item', () {
    final chains = List<Map<String, dynamic>>.from(
      kMockCryptoMultiAccounts['chains']! as List,
    );
    final firstChain = chains.first;

    for (final key in [
      'path',
      'childrenPath',
      'sourceFingerprint',
      'xfpFormat',
      'xpub',
      'publicKey',
      'chainCode',
      'name',
      'note',
    ]) {
      expect(kMockCryptoHDKey[key], firstChain[key], reason: key);
    }
  });

  test('all configured UR types have mock data and round-trip through parser',
      () {
    final configuredTypes = kUrTypeConfigs.map((config) => config.type).toSet();

    expect(
      configuredTypes,
      containsAll({
        'sc-sign-request',
        'scp-sign-request',
        'sc-signature',
        'bch-sign-request',
        'bch-signature',
        'keystone-tron-sign-request',
        'keystone-tron-sign-result',
        'keystone-cosmos-sign-request',
        'keystone-sol-sign-request',
        'xrp-sign-request',
        'xrp-signature',
        'xrp-account',
      }),
    );

    for (final config in kUrTypeConfigs) {
      final mock = kMockByType[config.type];
      expect(mock, isNotNull, reason: '${config.type} is missing mock data');

      final ur = buildUR(config.type, mock!);
      final parsed = parseUR(ur);

      expect(parsed['isError'], isNot(true), reason: '${config.type}: $parsed');
      expect(parsed['type'], isNotEmpty,
          reason: '${config.type} returned empty type');

      final fields = parsed['fields'] as Map<String, dynamic>;
      if (config.type == 'sc-sign-request' ||
          config.type == 'scp-sign-request') {
        expect(fields['requestId'], '123e4567-e89b-12d3-a456-426614174000');
        expect(fields['chain'], mock['chain']);
        expect(fields['signingPayloadData'], contains('siacoinOutputs'));
      } else if (config.type == 'sc-signature') {
        expect(fields['requestId'], '123e4567-e89b-12d3-a456-426614174000');
        expect(fields['broadcastTx'], contains('signature-bytes'));
      }
    }
  });
}
