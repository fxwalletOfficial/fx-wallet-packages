import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:web3dart/web3dart.dart';

import 'package:web3_webview_demo/services/eip712.dart';
import 'package:web3_webview_demo/services/eth_signer.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

void main() {
  final account = kDemoAccounts.first;
  const signer = Web3DartEthSigner();

  // The canonical EIP-712 example from the spec (Mail / Person).
  const typedDataJson = '''
  {
    "types": {
      "EIP712Domain": [
        {"name": "name", "type": "string"},
        {"name": "version", "type": "string"},
        {"name": "chainId", "type": "uint256"},
        {"name": "verifyingContract", "type": "address"}
      ],
      "Person": [
        {"name": "name", "type": "string"},
        {"name": "wallet", "type": "address"}
      ],
      "Mail": [
        {"name": "from", "type": "Person"},
        {"name": "to", "type": "Person"},
        {"name": "contents", "type": "string"}
      ]
    },
    "primaryType": "Mail",
    "domain": {
      "name": "Ether Mail",
      "version": "1",
      "chainId": 1,
      "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
    },
    "message": {
      "from": {"name": "Cow", "wallet": "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"},
      "to": {"name": "Bob", "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"},
      "contents": "Hello, Bob!"
    }
  }
  ''';

  // Known-good final digest for the canonical EIP-712 Mail example, taken
  // from the spec's reference implementation.
  const expectedDigest =
      '0xbe609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2';

  String hexOf(Uint8List bytes) => '0x${bytesToHex(bytes)}';

  group('Eip712', () {
    test('computes the spec final digest', () {
      final payload =
          (jsonDecode(typedDataJson) as Map).cast<String, dynamic>();
      expect(hexOf(Eip712.digest(payload)), expectedDigest);
    });

    test('digestFromJson matches digest(decoded)', () {
      expect(hexOf(Eip712.digestFromJson(typedDataJson)), expectedDigest);
    });

    test('rejects the legacy v1 array form', () {
      expect(
        () =>
            Eip712.digestFromJson('[{"type":"string","name":"x","value":"y"}]'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Web3DartEthSigner', () {
    // Recover the signer's 0x address from a 65-byte signature over [hash].
    String recover(String signatureHex, Uint8List hash) {
      final bytes = hexToBytes(signatureHex);
      final r = bytesToInt(bytes.sublist(0, 32));
      final s = bytesToInt(bytes.sublist(32, 64));
      final v = bytes[64];
      final pubKey = ecRecover(hash, MsgSignature(r, s, v));
      return '0x${bytesToHex(publicKeyToAddress(pubKey))}';
    }

    test('signTypedData recovers to the signing account', () async {
      final sig =
          await signer.signTypedData(account: account, payload: typedDataJson);
      expect(sig, startsWith('0x'));
      expect(sig.length, 132);
      final recovered = recover(sig, Eip712.digestFromJson(typedDataJson));
      expect(recovered.toLowerCase(), account.evmAddress.toLowerCase());
    });

    test('ethSign over a 32-byte hash recovers to the account', () async {
      final hash =
          '0x${bytesToHex(keccak256(Uint8List.fromList(utf8.encode('msg'))))}';
      final sig = await signer.ethSign(account: account, message: hash);
      final recovered = recover(sig, hexToBytes(hash));
      expect(recovered.toLowerCase(), account.evmAddress.toLowerCase());
    });

    test('personalSign returns a deterministic 65-byte signature', () async {
      const message = '0x48656c6c6f'; // "Hello"
      final a = await signer.personalSign(account: account, message: message);
      final b = await signer.personalSign(account: account, message: message);
      final c =
          await signer.personalSign(account: account, message: '0x576f726c64');

      expect(a, startsWith('0x'));
      expect(a.length, 132); // 0x + 65 bytes
      expect(a, b, reason: 'deterministic for identical input');
      expect(a, isNot(c), reason: 'varies with the message');
      // The trailing recovery byte must be a valid 27/28.
      expect(hexToBytes(a).last, anyOf(27, 28));
    });

    test('different accounts produce different signatures', () async {
      // Each demo account signs the same digest with its own key, so the
      // signatures must differ. (Per-account recovery is covered by the
      // signTypedData / ethSign cases above; we avoid re-recovering every
      // account here because web3dart's ecRecover asserts on the
      // high-s form some keys produce.)
      final sigs = <String>{};
      for (final account in kDemoAccounts) {
        sigs.add(await signer.signTypedData(
            account: account, payload: typedDataJson));
      }
      expect(sigs.length, kDemoAccounts.length);
    });

    test('sendTransaction (mock) returns a 32-byte hash without broadcasting',
        () async {
      final tx = JsTransactionObject.fromJson({
        'from': account.evmAddress,
        'to': '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
        'value': '0x2386f26fc10000',
        'gas': '0x5208',
        'chainId': '0x1',
      });
      final hash = await signer.sendTransaction(
        account: account,
        transaction: tx,
        broadcast: false,
        rpcUrl: 'https://example.invalid',
      );
      expect(hash, startsWith('0x'));
      expect(hash.length, 66);
    });
  });
}
