import 'package:crypto_wallet_util/src/config/chain/chains.dart';

/// Chain config list supported in this repository.
final List<ConfChain> chainConfigs = [
  // btc type address
  LTCChain(),
  DOGEChain(),
  BTCChain(),
  BCHChain(),
  BELChain(),
  // bech32 type address
  CKBChain(),
  HNSChain(),
  // cosmos type address
  ATOMChain(),
  KAVAChain(),
  SEIChain(),
  // eth type address
  ETHChain(),
  // kas type address
  KASChain(),
  KLSChain(),
  // sol type address
  SOLChain(),
  TONChain(),
  // base58 type address
  ALPHChain(),
  // base32 type address
  FILChain(),
  // regular type address
  ALEOChain(),
  APTOSChain(),
  DOTChain(),
  NEARChain(),
  SCChain(),
  SUIChain(),
  TRXChain(),
  XRPChain(),
  ICPChain(),
  ALGOChain(),
  // none type
  DefaultChain()
];

/// Obtain chain configuration through unique index [name].
ConfChain getChainConfig(String name) {
  if (name == 'kaspa') return KASChain();
  if (name == 'karlsen') return KLSChain();
  if (name == 'scp') return SCChain();
  for (final chainConfig in chainConfigs) {
    if (chainConfig.name == name) {
      return chainConfig;
    }
  }
  return DefaultChain();
}

/// get chain configuration by bip44Path
ConfChain getChainConfigByBip44Path(String bip44Path) {
  for (final chainConfig in chainConfigs) {
    if (chainConfig.mainnet.bip44Path == bip44Path) {
      return chainConfig;
    }
  }
  return DefaultChain();
}
