import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  final accounts = AccountGenerator.getSpecialEthAddress();
  for (final account in accounts) {
    // ignore: avoid_print
    print(account.address);
  }
}
