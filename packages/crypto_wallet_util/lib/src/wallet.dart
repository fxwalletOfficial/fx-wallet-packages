import 'package:crypto_wallet_util/src/config/config.dart';
import 'package:crypto_wallet_util/src/type/type.dart';
import 'package:crypto_wallet_util/wallets.dart';

/// Here is provided a suite of methods for the swift generation of [WalletType].
/// You can utilize the [Wallet] enumerated to generate the corresponding wallets,
/// either through a **mnemonic** or a **privateKey**.
enum Wallet {
  DOT,
  XRP,
  SUI,
  SC,
  CKB,
  HNS,
  ALPH,
  ATOM,
  SEI,
  KAVA,
  KAS,
  KLS,
  SOL,
  NEAR,
  APTOS,
  FIL,
  ETH,
  ICP,
  ALGO,
  TRX,
  BTC,
  DOGE,
  LTC,
  BCH,
  TAPROOT,
  NONE
}

Future<WalletType> getMnemonicWallet(String coin, String mnemonic) async {
  final wallet = getWallet(coin);
  final setting = getChainConfig(coin).mainnet;
  switch (wallet) {
    case Wallet.NONE:
      throw Exception('Unsupported chain');
    case Wallet.DOT:
      return DotCoin.fromMnemonic(mnemonic, setting);
    case Wallet.XRP:
      return XrpCoin.fromMnemonic(mnemonic, setting);
    case Wallet.SUI:
      return SuiCoin.fromMnemonic(mnemonic, setting);
    case Wallet.SC:
      return SiaCoin.fromMnemonic(mnemonic, setting);
    case Wallet.CKB:
      return CkbCoin.fromMnemonic(mnemonic, setting);
    case Wallet.HNS:
      return HnsCoin.fromMnemonic(mnemonic, setting);
    case Wallet.ALPH:
      return AlphCoin.fromMnemonic(mnemonic, setting);
    case Wallet.ATOM:
      return Cosmos.fromMnemonic(mnemonic, setting);
    case Wallet.SEI:
      return Cosmos.fromMnemonic(mnemonic, setting);
    case Wallet.KAVA:
      return Cosmos.fromMnemonic(mnemonic, setting);
    case Wallet.KAS:
      return KasCoin.fromMnemonic(mnemonic, setting);
    case Wallet.KLS:
      return KasCoin.fromMnemonic(mnemonic, setting);
    case Wallet.SOL:
      return SolCoin.fromMnemonic(mnemonic, setting);
    case Wallet.NEAR:
      return NearCoin.fromMnemonic(mnemonic, setting);
    case Wallet.APTOS:
      return AptosCoin.fromMnemonic(mnemonic, setting);
    case Wallet.FIL:
      return FileCoin.fromMnemonic(mnemonic, setting);
    case Wallet.ETH:
      return EthCoin.fromMnemonic(mnemonic, setting);
    case Wallet.ICP:
      return IcpCoin.fromMnemonic(mnemonic, setting);
    case Wallet.ALGO:
      return AlgoCoin.fromMnemonic(mnemonic, setting);
    case Wallet.TRX:
      return TrxCoin.fromMnemonic(mnemonic, setting);
    case Wallet.BTC:
      return BtcCoin.fromMnemonic(mnemonic, setting);
    case Wallet.DOGE:
      return DogeCoin.fromMnemonic(mnemonic, setting);
    case Wallet.LTC:
      return LtcCoin.fromMnemonic(mnemonic, setting);
    case Wallet.BCH:
      return BchCoin.fromMnemonic(mnemonic, setting);
    case Wallet.TAPROOT:
      return BtcCoin.fromMnemonic(mnemonic, null, true);
  }
}

WalletType getPrivateKeyWallet(String coin, String privateKey) {
  final wallet = getWallet(coin);
  final setting = getChainConfig(coin).mainnet;
  switch (wallet) {
    case Wallet.NONE:
      throw Exception('Unsupported chain');
    case Wallet.DOT:
      return DotCoin.fromPrivateKey(privateKey, setting);
    case Wallet.XRP:
      return XrpCoin.fromPrivateKey(privateKey, setting);
    case Wallet.SUI:
      return SuiCoin.fromPrivateKey(privateKey, setting);
    case Wallet.SC:
      return SiaCoin.fromPrivateKey(privateKey, setting);
    case Wallet.CKB:
      return CkbCoin.fromPrivateKey(privateKey, setting);
    case Wallet.HNS:
      return HnsCoin.fromPrivateKey(privateKey, setting);
    case Wallet.ALPH:
      return AlphCoin.fromPrivateKey(privateKey, setting);
    case Wallet.ATOM:
      return Cosmos.fromPrivateKey(privateKey, setting);
    case Wallet.SEI:
      return Cosmos.fromPrivateKey(privateKey, setting);
    case Wallet.KAVA:
      return Cosmos.fromPrivateKey(privateKey, setting);
    case Wallet.KAS:
      return KasCoin.fromPrivateKey(privateKey, setting);
    case Wallet.KLS:
      return KasCoin.fromPrivateKey(privateKey, setting);
    case Wallet.SOL:
      return SolCoin.fromPrivateKey(privateKey, setting);
    case Wallet.NEAR:
      return NearCoin.fromPrivateKey(privateKey, setting);
    case Wallet.APTOS:
      return AptosCoin.fromPrivateKey(privateKey, setting);
    case Wallet.FIL:
      return FileCoin.fromPrivateKey(privateKey, setting);
    case Wallet.ETH:
      return EthCoin.fromPrivateKey(privateKey, setting);
    case Wallet.ICP:
      return IcpCoin.fromPrivateKey(privateKey, setting);
    case Wallet.ALGO:
      return AlgoCoin.fromPrivateKey(privateKey, setting);
    case Wallet.TRX:
      return TrxCoin.fromPrivateKey(privateKey, setting);
    case Wallet.BTC:
      return BtcCoin.fromPrivateKey(privateKey, setting);
    case Wallet.DOGE:
      return DogeCoin.fromPrivateKey(privateKey, setting);
    case Wallet.LTC:
      return LtcCoin.fromPrivateKey(privateKey, setting);
    case Wallet.BCH:
      return BchCoin.fromPrivateKey(privateKey, setting);
    case Wallet.TAPROOT:
      return BtcCoin.fromPrivateKey(privateKey, null, true);
  }
}

Wallet getWallet(coin) {
  if (coin == 'kaspa') return Wallet.KAS;
  if (coin == 'karlsen') return Wallet.KLS;
  if (coin == 'scp') return Wallet.SC;
  return Wallet.values.firstWhere(
      (element) => (element.toString().split(".").last) == coin.toUpperCase(),
      orElse: () => Wallet.NONE);
}

List<String> supportCrypto() {
  const values = Wallet.values;
  final wallets = values.map((element) => element.toString().split(".").last);
  return wallets.toList();
}
