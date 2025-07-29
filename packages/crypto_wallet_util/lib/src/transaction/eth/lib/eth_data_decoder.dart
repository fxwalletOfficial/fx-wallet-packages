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

  /// Converts the parameter list returned by decodeParameters to a simplified Map format
  static Map<String, dynamic> formatParameters(List<dynamic> parameters) {
    final Map<String, dynamic> result = {};
    
    for (final param in parameters) {
      final String name = param['name'] as String;
      final String type = param['type'] as String;
      final dynamic value = param['value'];
      
      if (type == 'tuple') {
        // For tuple type, recursively process internal parameters
        result[name] = formatParameters(value as List<dynamic>);
      } else {
        // For other types, use the value directly
        result[name] = value;
      }
    }
    
    return result;
  }
}
