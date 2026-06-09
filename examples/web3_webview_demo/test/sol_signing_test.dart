import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

import 'package:web3_webview_demo/services/base58.dart';
import 'package:web3_webview_demo/services/sol_signer.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

void main() {
  final account = kDemoAccounts.first;
  const signer = Ed25519SolSigner();
  final ed = Ed25519();

  // Verify an ed25519 signature [sig] over [message] for [account].
  Future<bool> verify(
      Uint8List sig, Uint8List message, DemoAccount account) async {
    final keyPair = await ed.newKeyPairFromSeed(hexDecode(account.solanaSeed));
    final pub = await keyPair.extractPublicKey();
    return ed.verify(
      message,
      signature: Signature(sig, publicKey: pub),
    );
  }

  group('base58 codec', () {
    test('round-trips arbitrary bytes', () {
      final cases = [
        Uint8List.fromList([0, 0, 1, 2, 3]),
        Uint8List.fromList(List.generate(32, (i) => i)),
        Uint8List.fromList([255, 254, 253]),
      ];
      for (final bytes in cases) {
        expect(base58Decode(base58Encode(bytes)), bytes);
      }
    });

    test('preserves leading zeros as 1s', () {
      final bytes = Uint8List.fromList([0, 0, 5]);
      final encoded = base58Encode(bytes);
      expect(encoded, startsWith('11'));
      expect(base58Decode(encoded), bytes);
    });

    test('rejects invalid characters', () {
      expect(() => base58Decode('0OIl'), throwsFormatException);
    });
  });

  group('Ed25519SolSigner addresses', () {
    test('catalogue solanaAddress matches the seed-derived public key',
        () async {
      for (final account in kDemoAccounts) {
        final derived = await signer.addressOf(account);
        expect(derived, account.solanaAddress, reason: account.label);
      }
    });
  });

  group('Ed25519SolSigner signing', () {
    test('signMessage returns a verifiable hex signature', () async {
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final data = JsCallBackData(
        method: 'solana_signMessage',
        params: {'raw': '0x${hexEncode(message)}'},
      );
      final sigHex = await signer.signMessage(account: account, data: data);

      expect(sigHex, startsWith('0x'));
      final sig = hexDecode(sigHex);
      expect(sig.length, 64);
      expect(await verify(sig, message, account), isTrue);
    });

    test('signTransaction returns a verifiable base58 signature', () async {
      final message = Uint8List.fromList(List.generate(40, (i) => i));
      final data = JsCallBackData(
        method: 'solana_signTransaction',
        params: {
          'raw': hexEncode(message),
          'message': 'unused-base64',
        },
      );
      final sigB58 =
          await signer.signTransaction(account: account, data: data);

      final sig = base58Decode(sigB58);
      expect(sig.length, 64);
      expect(await verify(sig, message, account), isTrue);
    });

    test('different accounts produce different signatures', () async {
      final data = JsCallBackData(
        method: 'solana_signMessage',
        params: {'raw': '0xabcdef'},
      );
      final sigs = <String>{};
      for (final account in kDemoAccounts) {
        sigs.add(await signer.signMessage(account: account, data: data));
      }
      expect(sigs.length, kDemoAccounts.length);
    });
  });
}
