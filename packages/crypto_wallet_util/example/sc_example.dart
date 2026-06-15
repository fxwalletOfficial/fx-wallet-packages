// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto_wallet_util/transaction.dart';
import 'package:crypto_wallet_util/src/wallets/sc.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  final mnemonic = Platform.environment['SC_MNEMONIC']!;
  final receiver = Platform.environment['SC_TO']!;
  final amount = Platform.environment['SC_AMOUNT']!;
  final apiBase = Platform.environment['SC_API_BASE']!;

  // ---- 1. Derive account ------------------------------------------------
  final wallet = await SiaCoin.fromMnemonic(mnemonic);
  print('1. address: ${wallet.address}');

  // ---- 2. Create unsigned transaction via API ---------------------------
  final client = HttpClient();
  final req = await client.postUrl(Uri.parse('$apiBase/v2/wallet/sc/tx'));
  req.headers.set('Content-Type', 'application/json');
  req.headers.set('User-Agent', 'fx-wallet');
  req.headers.set('x-pubkey', wallet.address);
  req.write(json.encode({
    'raw_public_key': dynamicToString(wallet.publicKey),
    'outputs': [
      {'address': receiver, 'amount': amount}
    ],
    'subtract_fee': false,
  }));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  client.close();
  print(body);

  final createResp = json.decode(body);
  final signingPayload = createResp['signing_payload'];
  print('2. fee: ${createResp['fee']}');

  // ---- 3. WASM digest ---------------------------------------------------
  final unsignedTx = ScUnsignedTransaction.fromJson(signingPayload['data']);
  final builder = await ScTransactionBuilder.create();
  final txData = await builder.build(unsignedTx);

  for (var i = 0; i < txData.toSign.length; i++) {
    print('3. digest[$i]: ${txData.toSign[i]}');
  }

  // ---- 4. Sign ----------------------------------------------------------
  final signer = ScTxSigner(wallet, txData);
  signer.sign();

  final sigs = (txData.transaction['siacoinInputs'] as List)
      .first['satisfiedPolicy']['signatures'] as List;
  print('4. signature: ${sigs.first}');

  // ---- 5. Broadcast -----------------------------------------------------
  if (Platform.environment['SC_BROADCAST'] != '1') {
    print('5. dry-run, broadcast payload:');
    print(json.encode(txData.toBroadcast()));
    return;
  }

  final bcReq = await HttpClient()
      .postUrl(Uri.parse('$apiBase/coin/sc/broadcast'));
  bcReq.headers.set('Content-Type', 'application/json');
  bcReq.headers.set('User-Agent', 'fx-wallet');
  bcReq.write(json.encode({'tx': txData.toBroadcast()}));
  final bcResp = await bcReq.close();
  final bcBody = await bcResp.transform(utf8.decoder).join();
  print('5. broadcast: $bcBody');
}
