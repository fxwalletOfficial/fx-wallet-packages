/**
 * Constants for bip44 path, address prefix and regular expression for address. 
 */
/// ALPH_PATH: m/44'/1234'/0'/0/0
const ALPH_PATH = "m/44'/1234'/0'/0/0";

/// APTOS_PATH: "m/44'/637'/0'/0'/0'";
const APTOS_PATH = "m/44'/637'/0'/0'/0'";

/// CKB_PATH: "m/44'/309'/0'/0/0";
const CKB_PATH = "m/44'/309'/0'/0/0";

/// ATOM_PATH: "m/44'/118'/0'/0/0";
const ATOM_PATH = "m/44'/118'/0'/0/0";

/// KAVA_PATH: "m/44'/459'/0'/0/0";
const KAVA_PATH = "m/44'/459'/0'/0/0";

/// DOT_PATH: "m/44'/354'/0'/0'/0'";
const DOT_PATH = "m/44'/354'/0'/0'/0'";

/// HNS_PATH: "m/44'/5353'/0'/0/0";
const HNS_PATH = "m/44'/5353'/0'/0/0";

/// KAS_PATH: "m/44'/111111'/0'/0/0";
const KAS_PATH = "m/44'/111111'/0'/0/0";

/// KLS_PATH: "m/44'/121337'/0'";
const KLS_PATH = "m/44'/121337'/0'";

/// NEAR_PATH: "m/44'/397'/0'";
const NEAR_PATH = "m/44'/397'/0'";

/// SOL_PATH: "m/44'/501'/0'/0'";
const SOL_PATH = "m/44'/501'/0'/0'";

/// SUI_PATH: "m/44'/784'/0'/0'/0'";
const SUI_PATH = "m/44'/784'/0'/0'/0'";

/// XRP_PATH: "m/44'/144'/0'/0/0";
const XRP_PATH = "m/44'/144'/0'/0/0";

/// BCH_PATH: "m/44'/145'/0'/0/0";
const BCH_PATH = "m/44'/145'/0'/0/0";

/// BTC_PATH: "m/44'/0'/0'/0/0";
const BTC_PATH = "m/44'/0'/0'/0/0";

/// TAPROOT_PATH: "m/86'/0'/0'/0/0";
const TAPROOT_PATH = "m/86'/0'/0'/0/0";

/// DOGE_PATH: "m/44'/3'/0'/0/0";
const DOGE_PATH = "m/44'/3'/0'/0/0";

/// LTC_PATH: "m/44'/2'/0'/0/0";
const LTC_PATH = "m/44'/2'/0'/0/0";

/// TRX_PATH: "m/44'/195'/0'/0/0";
const TRX_PATH = "m/44'/195'/0'/0/0";

/// ETH_PATH: "m/44'/60'/0'/0/0";
const ETH_PATH = "m/44'/60'/0'/0/0";

/// ICP_PATH : "m/44'/223'/0'/0/0";
const ICP_PATH = "m/44'/223'/0'/0/0";

/// CKB_PREFIX: ckb;
const CKB_PREFIX = 'ckb';

/// ATOM_PREFIX: cosmos;
const ATOM_PREFIX = 'cosmos';

/// KAVA_PREFIX: kava;
const KAVA_PREFIX = 'kava';

/// SEI_PREFIX: sei;
const SEI_PREFIX = 'sei';

/// HNS_PREFIX: hs;
const HNS_PREFIX = 'hs';

/// KAS_PREFIX: kaspa;
const KAS_PREFIX = "kaspa";

/// KLS_PREFIX: karlsen;
const KLS_PREFIX = "karlsen";

/// BITCOINCASH_PREFIX: bitcoincash;
const BITCOINCASH_PREFIX = 'bitcoincash';

/// BTC_ADDRESS_REG: ```^([a-km-zA-HJ-NP-Z1-9]{27,34})|(bitcoincash:[a-z0-9]{42})|(bc[a-zA-Z0-9]{25,87})$```
const String BTC_ADDRESS_REG =
    r'^([a-km-zA-HJ-NP-Z1-9]{27,34})|(bitcoincash:[a-z0-9]{42})|(bc[a-zA-Z0-9]{25,87})$';

/// ETH_ADDRESS_REG: ```^0x[a-fA-F0-9]{40}$```
const String ETH_ADDRESS_REG = r'^0x[a-fA-F0-9]{40}$';

/// TRX_ADDRESS_REG: ```^T[a-zA-Z0-9]{33}```
const String TRX_ADDRESS_REG = r'^T[a-zA-Z0-9]{33}';

/// SUI_ADDRESS_REG: ```^0x[0-9a-f]{64}$```
const String SUI_ADDRESS_REG = r'^0x[0-9a-f]{64}$';

/// XRP_ADDRESS_REG: ```^r(?![IOl])[0-9a-km-zA-HJ-NP-Z]{25,35}$```
const String XRP_ADDRESS_REG = r'^r(?![IOl])[0-9a-km-zA-HJ-NP-Z]{25,35}$';

/// DOT_ADDRESS_REG: ```^[1|5][a-zA-Z0-9]{46,47}$```
const String DOT_ADDRESS_REG = r'^[1|5][a-zA-Z0-9]{46,47}$';

/// SC_ADDRESS_REG: ```^[a-z0-9]{76}$```
const String SC_ADDRESS_REG = r'^[a-z0-9]{76}$';

/// ALPH_ADDRESS_REG: ```^[1-9A-HJ-NP-Za-km-z]+$```
const String ALPH_ADDRESS_REG = r'^[1-9A-HJ-NP-Za-km-z]+$';

/// SOL_ADDRESS_REG: ```^([1-9A-HJ-NP-Za-km-z]{44})$```
const String SOL_ADDRESS_REG = r'^([1-9A-HJ-NP-Za-km-z]{44})$';

/// NEAR_ADDRESS_REG: ```^[0-9a-fA-F]{64}$```
const String NEAR_ADDRESS_REG = r'^[0-9a-fA-F]{64}$';

/// APTOS_ADDRESS_REG: ```^0x[a-fA-F0-9]{64}$```
const String APTOS_ADDRESS_REG = r'^0x[a-fA-F0-9]{64}$';

/// ICP_ADDRESS_REG: ```^[0-9a-fA-F]{64}$```
const String ICP_ADDRESS_REG = r'^[0-9a-fA-F]{64}$';

/// COMMON_REG: ```^[?()=#~+%@.:\-_a-zA-Z0-9]+$```
const String COMMON_REG = r'^[?()=#~+%@.:\-_a-zA-Z0-9]+$';

/// COMMON_REG: ```^[?()=#~+%@.:\-_a-zA-Z0-9]+$```
const String FILECOIN_MAINNET_REG =
    r'^(f[1-4][qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)|(f410[a-zA-Z0-9]+)$';
const String FILECOIN_TESTNET_REG = r'^t1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]+$';

/// ALEO_REG: ```^aleo1[a-z0-9]{58}$```
const String ALEO_REG = r'^aleo1[a-z0-9]{58}$';

/// FILECOIN_PATH: "m/44'/461'/0'/0/0";
const FILECOIN_PATH = "m/44'/461'/0'/0/0";

/// FILECOIN_PREFIX_MAINNET: f1;
const FILECOIN_PREFIX_MAINNET = 'f1';

/// FILECOIN_PREFIX_EVM: f1;
const FILECOIN_PREFIX_EVM = 'f410';

/// FILECOIN_PREFIX_TESTNET: f1;
const FILECOIN_PREFIX_TESTNET = 't1';

/// ALGO_PATH: "m/44'/283'/0'/0/0";
const ALGO_PATH = "m/44'/283'/0'/0'/0'";

/// ALGO_REG : ```^[qpzry9x8gf2tvdw0s3jn54khce6mua7l]+$```
const String ALGO_REG = r'^[abcdefghijklmnopqrstuvwxyz234567]+$';
