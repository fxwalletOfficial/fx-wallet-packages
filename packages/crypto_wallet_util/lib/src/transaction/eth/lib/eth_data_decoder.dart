import 'dart:convert';
import 'dart:io';

import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/abi_decoder.dart';

class EthDataDecoder {
  static final AbiDecoder paraSwap = AbiDecoder.fromABI(json.decode(
      File('./lib/src/transaction/eth/lib/abi/paraswap_abi.json')
          .readAsStringSync(encoding: utf8)));

  static decodeByAbi(List<dynamic> abiJson, String data) {
    final decoder = AbiDecoder.fromABI(abiJson);
    return decoder.decodeParameters(data);
  }
}
