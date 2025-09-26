import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/abi_decoder.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/abi/cowswap_abi.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/abi/paraswap_abi.dart';

class EthDataDecoder {
  static final AbiDecoder paraSwap = AbiDecoder.fromABI(paraSwapAbi);
  static final AbiDecoder cowSwap = AbiDecoder.fromABI(cowswapAbi);

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
