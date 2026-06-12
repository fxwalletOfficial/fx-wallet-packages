// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto_wallet_util/transaction.dart';
import 'package:crypto_wallet_util/src/wallets/sc.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  final mnemonic = Platform.environment['SCP_MNEMONIC'];
  final receiver = Platform.environment['SCP_TO'];
  final amount = Platform.environment['SC_AMOUNT'];
  final apiBase = Platform.environment['SC_API_BASE'];
  final shouldBroadcast = Platform.environment['SC_BROADCAST'] == '1';

  // Validate required environment variables
  final missing = <String>[];
  if (mnemonic == null || mnemonic.isEmpty) missing.add('SCP_MNEMONIC');
  if (receiver == null || receiver.isEmpty) missing.add('SCP_TO');
  if (amount == null || amount.isEmpty) missing.add('SC_AMOUNT');
  if (apiBase == null || apiBase.isEmpty) missing.add('SC_API_BASE');

  if (missing.isNotEmpty) {
    print(
      'Error: Missing required environment variables: ${missing.join(', ')}\n'
      'Usage:\n'
      '  SCP_MNEMONIC="..." SCP_TO="..." SC_AMOUNT="..." '
      'SC_API_BASE="..." dart run example/scp_example.dart\n'
      'Optional: SC_BROADCAST=1 to broadcast the transaction.',
    );
    return;
  }
  const subtractFee = false;
  const isCrossChain = false;

  // ---- 1. Derive account ------------------------------------------------
  final wallet = await SiaCoin.fromMnemonic(mnemonic!);
  print('1. Derived SCP account');
  print(
    json.encode({
      'address': wallet.address,
      'publicKey': dynamicToString(wallet.publicKey),
    }),
  );

  // ---- 2. Create unsigned transaction via API ---------------------------
  print('\n2. Calling SCP V2 create transaction API');
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse('${apiBase!}/v2/wallet/scp/tx'));
  req.headers.set('Content-Type', 'application/json');
  req.headers.set('User-Agent', 'fx-wallet');
  req.headers.set('x-pubkey', wallet.address);
  req.write(
    json.encode({
      'raw_public_key': dynamicToString(wallet.publicKey),
      'outputs': [
        {'address': receiver!, 'amount': amount!},
      ],
      'is_cross_chain': isCrossChain,
      'subtract_fee': subtractFee,
    }),
  );
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  client.close();

  final createResp = json.decode(body);
  final signingPayload = createResp['signing_payload'];

  if (createResp['status'] != 'success' ||
      signingPayload?['type'] != 'scp_unsigned_transaction' ||
      signingPayload?['data'] == null) {
    print('Unexpected createTxV2 response:');
    print(json.encode(createResp));
    return;
  }

  print('\nCreateTxV2 summary:');
  print(
    json.encode({
      'fee': createResp['fee'],
      'cross_chain_fee': createResp['cross_chain_fee'],
      'payload_type': signingPayload['type'],
      'input_count':
          (signingPayload['data']['siacoinInputs'] as List?)?.length ?? 0,
      'output_count':
          (signingPayload['data']['siacoinOutputs'] as List?)?.length ?? 0,
      'signature_count':
          (signingPayload['data']['transactionSignatures'] as List?)?.length ??
          0,
      'signing_info': createResp['signing_info'],
    }),
  );

  // ---- 3. Compute digest (pure Dart, no WASM) ----------------------------
  print('\n3. Generating SCP digests locally from transaction object');
  final unsignedTx = ScpUnsignedTransaction.fromJson(signingPayload['data']);
  final digests = ScpSigHash.computeDigests(unsignedTx);

  for (var i = 0; i < digests.length; i++) {
    print('  digest[$i]: ${digests[i]}');
  }

  // ---- 4. Sign -----------------------------------------------------------
  print('\n4. Signing every input digest');
  final txMap = Map<String, dynamic>.from(signingPayload['data']);
  final sigEntries = unsignedTx.transactionSignatures
      .map(
        (e) => ScpTransactionSignature(
          parentID: e.parentID,
          publicKeyIndex: e.publicKeyIndex,
          coveredFields: e.coveredFields,
        ),
      )
      .toList();

  final txData = ScpTxData(
    transaction: txMap,
    toSign: digests,
    transactionSignatures: sigEntries,
  );

  final signer = ScpTxSigner(wallet, txData);
  signer.sign();

  final txSigs = txData.transaction['transactionSignatures'] as List;
  print(
    json.encode(
      txSigs
          .map(
            (item) => {
              'index': txSigs.indexOf(item),
              'parentID': item['parentID'],
              'signatureBase64': item['signature'],
            },
          )
          .toList(),
    ),
  );

  // ---- 5. Broadcast ------------------------------------------------------
  final broadcastPayload = txData.toBroadcast();

  if (!shouldBroadcast) {
    print('\n5. Broadcast skipped. Set SC_BROADCAST=1 to broadcast.');
    print(json.encode({'tx': broadcastPayload}));
    return;
  }

  print('\n5. Broadcasting signed SCP transaction');
  final bcReq = await HttpClient().postUrl(
    Uri.parse('${apiBase!}/coin/scp/broadcast'),
  );
  bcReq.headers.set('Content-Type', 'application/json');
  bcReq.headers.set('User-Agent', 'fx-wallet');
  bcReq.write(json.encode({'tx': broadcastPayload}));
  final bcResp = await bcReq.close();
  final bcBody = await bcResp.transform(utf8.decoder).join();
  print(bcBody);
}
