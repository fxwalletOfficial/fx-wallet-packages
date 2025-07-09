import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/transaction/hns/hns_lib.dart';

void main() {
  test('test hns sign', () async {
    String mnemonic =
        'number vapor draft title message quarter hour other hotel leave shrug donor';

    /// The transaction information returned by the api
    MTX info = MTX.fromJson({
      'inputs': [
        {
          'prevout': {
            'hash':
                '10441a91c6704c29baa6fb6171e2e521df436143c5d64b45cc7c308cb6b8ccea',
            'index': 1
          },
          'witness': [
            '',
            '03a437e8f5e82fbbbfc1c3c6eb7d34c4af6d2cf945e0ccef3fa910c00f20431df7'
          ],
          'sequence': 4294967295,
          'coin': {
            'version': 0,
            'height': 8137,
            'value': 1755988860,
            'address': 'rs1q9r8m2cgketr5q6s0gh00ykmctg5gvfcek77wym',
            'covenant': {'type': 0, 'action': 'NONE', 'items': []},
            'coinbase': false
          },
          'path': {
            'account': 0,
            'change': true,
            'derivation': "m/44'/5355'/0'/1/17"
          }
        }
      ],
      'outputs': [
        {
          'value': 55997200,
          'address': 'rs1qdwkq5n9ytt6krvjfxhutfludwux6v0njg20yam',
          'covenant': {'type': 0, 'action': 'NONE', 'items': []}
        },
        {
          'value': 1699988860,
          'address': 'rs1qcaf4l2st2q45tman469f3ad7e360y0s25d53et',
          'covenant': {'type': 0, 'action': 'NONE', 'items': []}
        }
      ],
      'hex':
          '000000000110441a91c6704c29baa6fb6171e2e521df436143c5d64b45cc7c308cb6b8ccea01000000ffffffff02107356030000000000146bac0a4ca45af561b24935f8b4ff8d770da63e7200007cc55365000000000014c7535faa0b502b45efb3ae8a98f5becc74f23e0a00000000000002002103a437e8f5e82fbbbfc1c3c6eb7d34c4af6d2cf945e0ccef3fa910c00f20431df7',
      'version': 0,
      'locktime': 0
    });

    /// Transaction Signature
    final txHex = FxHnsSign(mtx: info, mnemonic: mnemonic).sign();
    expect(txHex,
        '000000000110441a91c6704c29baa6fb6171e2e521df436143c5d64b45cc7c308cb6b8ccea01000000ffffffff02107356030000000000146bac0a4ca45af561b24935f8b4ff8d770da63e7200007cc55365000000000014c7535faa0b502b45efb3ae8a98f5becc74f23e0a0000000000000241b34e0bded7bf20dfacfc6db0f0a0e6366093a47010f6696ba37a93ca17c600f060a4920b1bfbe2e6081552d47258be1f718bf451f15310116a6cf405d6d1e059012103a437e8f5e82fbbbfc1c3c6eb7d34c4af6d2cf945e0ccef3fa910c00f20431df7');
  });
}
