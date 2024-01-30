import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

void main() {
  final private_key =
      'APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH';
  final recipient =
      "aleo1x6mskfv6yaem7jzxplj9fc9eyqek89e8syv4xud24gal5hl70qyq90wt3y";
  final amount_credits = 1.0;
  final transfer_type = 'public';
  final fee_credits = 1.0;
  final url = 'http://23.20.9.85:3033';
  test('buildTransferTransaction', () {
    final tx = buildTransferTransaction(private_key, amount_credits,
        transfer_type, recipient, fee_credits, url);
    print(tx);
  });
}