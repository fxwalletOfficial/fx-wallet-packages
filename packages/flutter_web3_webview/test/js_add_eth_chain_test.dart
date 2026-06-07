import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/models/js_add_eth_chain.dart';

void main() {
  group('JsAddEthereumChain', () {
    test('creates an empty chain', () {
      final chain = JsAddEthereumChain();

      expect(chain.chainId, isNull);
      expect(chain.data, isNull);
      expect(chain.toJson(), {'chainId': null});
    });

    test('preserves all chain fields when parsed and serialized', () {
      final chain = JsAddEthereumChain.fromJson({
        'chainId': '0x89',
        'chainName': 'Polygon',
        'rpcUrls': ['https://polygon-rpc.example'],
      });

      expect(chain.chainId, '0x89');
      expect(chain.toJson(), {
        'chainId': '0x89',
        'chainName': 'Polygon',
        'rpcUrls': ['https://polygon-rpc.example'],
      });
    });

    test('ignores an invalid chain id while preserving other fields', () {
      final chain = JsAddEthereumChain.fromJson({
        'chainId': 137,
        'chainName': 'Polygon',
      });

      expect(chain.chainId, isNull);
      expect(chain.toJson(), {
        'chainId': null,
        'chainName': 'Polygon',
      });
    });

    test('does not expose a mutable reference to input data', () {
      final input = <String, dynamic>{
        'chainId': '0x1',
        'chainName': 'Ethereum',
      };
      final chain = JsAddEthereumChain.fromJson(input);

      input['chainName'] = 'Changed';

      expect(chain.data?['chainName'], 'Ethereum');
    });
  });
}
