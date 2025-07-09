import 'dart:io';

import 'package:crypto_wallet_util/src/config/chain/chain_configs.dart';
import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() {
  final jsonData = json.decode(File('./test/address/data/address.json')
      .readAsStringSync(encoding: utf8));
  group('check address', () {
    for (final data in jsonData['example']) {
      final String name = data['name'];
      List<dynamic> addresses = data['address'];
      List<dynamic> errorAddresses = data['error'];
      // ignore: avoid_print
      if (addresses.length == 0 || errorAddresses == 0) print(name);

      final chainConfig = getChainConfig(name);
      final walletSetting = chainConfig.mainnet;
      test(name, () {
        for (final address in addresses) {
          assert(AddressUtils.checkAddressValid(address, walletSetting));
        }
      });

      test('error $name', () {
        for (final address in errorAddresses) {
          final result = AddressUtils.checkAddressValid(address, walletSetting);
          // ignore: avoid_print
          if (result) print(address);
          // assert(!AddressUtils.checkAddressValid(address, walletSetting));
        }
      });
    }
  });

  test('get address type', () {
    final results = [];
    for (final data in jsonData['example']) {
      for (final address in data['address']) {
        List<String> types = [];
        for (final config in chainConfigs) {
          if (config.name == 'default') continue;
          final isThisType =
              AddressUtils.checkAddressValid(address, config.mainnet);
          if (isThisType) {
            types.add(config.name);
          }
        }
        final result = {'name': data['name'], 'types': types};
        results.add(result);
      }
    }
    // ignore: avoid_print
    print(jsonEncode(results));
  });
}
