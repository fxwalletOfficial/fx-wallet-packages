import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';

// Coin type numbers from SLIP-0044
// https://github.com/satoshilabs/slips/blob/master/slip-0044.md
class CoinType {
  static const int BTC = 0;
  static const int ETH = 60;
  static const int TRX = 195;
  static const int SOL = 501;
  static const int COSMOS = 118;
  static const int ALPH = 1234;

  // Network types
  static const int MAINNET = 0;
  static const int TESTNET = 1;
}

/// CryptoCoinInfo - field 5: use_info
/// Identifies the cryptocurrency and network for the HD Key
class CryptoCoinInfo extends RegistryItem {
  final int coinType; // field 1: SLIP-0044 coin type (e.g., 0=BTC, 60=ETH)
  final int? network; // field 2: network identifier (0=mainnet, 1=testnet)

  /// Default constructor for creating a new instance
  CryptoCoinInfo({
    required this.coinType,
    this.network,
  });

  /// Empty constructor for decoding
  CryptoCoinInfo.empty()
      : coinType = 0,
        network = null;

  @override
  RegistryType getRegistryType() => RegistryType.CRYPTO_COIN_INFO;

  @override
  CborValue toCborValue() {
    return CborMap({
      CborSmallInt(1): CborInt(BigInt.from(coinType)),
      if (network != null) CborSmallInt(2): CborInt(BigInt.from(network!)),
    }, tags: [
      getRegistryType().tag
    ]);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final coinType = RegistryItem.readInt(map, 1);
    final network = RegistryItem.readOptionalInt(map, 2);

    return CryptoCoinInfo(
      coinType: coinType,
      network: network,
    );
  }

  String getCoinName() {
    switch (coinType) {
      case CoinType.BTC:
        return 'BTC';
      case CoinType.ETH:
        return 'ETH';
      case CoinType.TRX:
        return 'TRX';
      case CoinType.SOL:
        return 'SOL';
      case CoinType.COSMOS:
        return 'ATOM';
      case CoinType.ALPH:
        return 'ALPH';
      default:
        return 'Unknown';
    }
  }

  /// Check if this is mainnet
  bool isMainnet() => network == null || network == CoinType.MAINNET;

  /// Check if this is testnet
  bool isTestnet() => network == CoinType.TESTNET;

  @override
  String toString() =>
      '{"coinType":$coinType,"coinName":"${getCoinName()}","network":${network ?? 0}}';
}
