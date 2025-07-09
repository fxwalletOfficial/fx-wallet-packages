import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  const String mnemonic =
      'vapidly pause vexed ghost hounded romance gained anxiety number semifinal tonic return roomy symptoms sizes pencil gifts civilian opened opposite pastry sugar vapidly smidgen ledge baffles thorn rhino abducts';
final wallet = await SiaCoin.fromMnemonic(mnemonic);
  test('test', () async {
    expect(wallet.address, '77f5755bb388a7cf05770228cbc0b93800d68bc4d0cb50e9f2c64707915702549bf88b2448ce');
  });
}
