import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/models/settings.dart';

void main() {
  group('Web3Settings Tests', () {
    test('should create Web3Settings with default values', () {
      final settings = Web3Settings();
      expect(settings.name, isNull);
      expect(settings.eth, isNull);
      expect(settings.sol, isNull);
    });

    test('should create Web3Settings with custom values', () {
      final ethSettings = Web3EthSettings(chainId: 1, icon: 'eth.png', rdns: 'eth.example.com');
      final solSettings = Web3SolSettings(icon: 'sol.png');
      final settings = Web3Settings(
        name: 'Test App',
        eth: ethSettings,
        sol: solSettings,
      );

      expect(settings.name, equals('Test App'));
      expect(settings.eth, equals(ethSettings));
      expect(settings.sol, equals(solSettings));
    });
  });

  group('Web3EthSettings Tests', () {
    test('should create Web3EthSettings with default values', () {
      final ethSettings = Web3EthSettings();
      expect(ethSettings.chainId, isNull);
      expect(ethSettings.icon, isNull);
      expect(ethSettings.rdns, isNull);
    });

    test('should create Web3EthSettings with custom values', () {
      final ethSettings = Web3EthSettings(
        chainId: 1,
        icon: 'eth.png',
        rdns: 'eth.example.com',
      );

      expect(ethSettings.chainId, equals(1));
      expect(ethSettings.icon, equals('eth.png'));
      expect(ethSettings.rdns, equals('eth.example.com'));
    });
  });

  group('Web3SolSettings Tests', () {
    test('should create Web3SolSettings with default values', () {
      final solSettings = Web3SolSettings();
      expect(solSettings.icon, isNull);
    });

    test('should create Web3SolSettings with custom values', () {
      final solSettings = Web3SolSettings(icon: 'sol.png');
      expect(solSettings.icon, equals('sol.png'));
    });
  });
}