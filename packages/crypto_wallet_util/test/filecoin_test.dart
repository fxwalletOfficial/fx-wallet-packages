import 'package:crypto_wallet_util/src/wallets/fil.dart';
import 'package:test/test.dart';

void main() async {
  test('test evm address to filecoin', () {
    const evmAddress = "0x6baf68ffe6386d435ba6d253299331264e147b42";
    final filecoinAddress = FileCoin.getF410Address(evmAddress);

    final expectedAddress = 'f410fnoxwr77ghbwugw5g2jjstezrezhbi62cdqsv4ua';

    expect(filecoinAddress, expectedAddress);
  });
}
