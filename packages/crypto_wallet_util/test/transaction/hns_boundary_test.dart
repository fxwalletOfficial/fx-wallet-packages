import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/transaction/hns/hns_lib.dart';

/// Regression test for F13: FxHnsSign.sign() parsed input count, output
/// count, output address length, covenant item count, and each covenant
/// item length as single bytes with no bounds check. Once any of those
/// fields reached the varint boundary (253), the old code would silently
/// read the wrong byte offsets and sign over the wrong data instead of
/// failing. The fix makes it fail loudly (an Exception) instead, since a
/// full varint implementation isn't safe to add without confirming HNS's
/// exact wire format for these specific fields.
void main() {
  const mnemonic =
      'number vapor draft title message quarter hour other hotel leave shrug donor';

  Map<String, dynamic> baseInput() => {
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
        'path': {'account': 0, 'change': true, 'derivation': "m/44'/5355'/0'/1/17"}
      };

  Map<String, dynamic> baseOutput() => {
        'value': 55997200,
        'address': 'rs1qdwkq5n9ytt6krvjfxhutfludwux6v0njg20yam',
        'covenant': {'type': 0, 'action': 'NONE', 'items': []}
      };

  test('sign() throws instead of misparsing at 253 outputs', () {
    final info = MTX.fromJson({
      'inputs': [baseInput()],
      'outputs': List.generate(253, (_) => baseOutput()),
      'hex':
          '000000000110441a91c6704c29baa6fb6171e2e521df436143c5d64b45cc7c308cb6b8ccea01000000ffffffff02107356030000000000146bac0a4ca45af561b24935f8b4ff8d770da63e7200007cc55365000000000014c7535faa0b502b45efb3ae8a98f5becc74f23e0a00000000000002002103a437e8f5e82fbbbfc1c3c6eb7d34c4af6d2cf945e0ccef3fa910c00f20431df7',
      'version': 0,
      'locktime': 0
    });

    expect(() => FxHnsSign(mtx: info, mnemonic: mnemonic).sign(),
        throwsException);
  });

  test('sign() throws instead of misparsing at 253 inputs', () {
    final info = MTX.fromJson({
      'inputs': List.generate(253, (_) => baseInput()),
      'outputs': [baseOutput()],
      'hex':
          '000000000110441a91c6704c29baa6fb6171e2e521df436143c5d64b45cc7c308cb6b8ccea01000000ffffffff02107356030000000000146bac0a4ca45af561b24935f8b4ff8d770da63e7200007cc55365000000000014c7535faa0b502b45efb3ae8a98f5becc74f23e0a00000000000002002103a437e8f5e82fbbbfc1c3c6eb7d34c4af6d2cf945e0ccef3fa910c00f20431df7',
      'version': 0,
      'locktime': 0
    });

    expect(() => FxHnsSign(mtx: info, mnemonic: mnemonic).sign(),
        throwsException);
  });

  test('sign() still works normally for an ordinary transaction', () {
    final info = MTX.fromJson({
      'inputs': [baseInput()],
      'outputs': [
        baseOutput(),
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

    expect(() => FxHnsSign(mtx: info, mnemonic: mnemonic).sign(),
        returnsNormally);
  });
}
