import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/dot.dart';

void main() async {
  const String mnemonic =
      'caution juice atom organ advance problem want pledge someone senior holiday very';
  final dot = await DotCoin.fromMnemonic(mnemonic);

  group('test dot address generate by', () {
    test('prefix 2', () async {
      expect(
          dot.kusamaAddress, 'HRkCrbmke2XeabJ5fxJdgXWpBRPkXWfWHY8eTeCKwDdf4k6');
    });

    test('prefix 42', () async {
      expect(dot.rococoAddress,
          '5Gv8YYFu8H1btvmrJy9FjjAWfb99wrhV3uhPFoNEr918utyR');
    });
  });
}
