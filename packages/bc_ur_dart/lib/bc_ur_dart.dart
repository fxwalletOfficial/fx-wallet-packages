library bc_ur_dart;

// Chain and account models.
export 'package:bc_ur_dart/src/models/alph/alph_sign_request.dart';
export 'package:bc_ur_dart/src/models/alph/alph_signature.dart';
export 'package:bc_ur_dart/src/models/bch/bch_sign_request.dart';
export 'package:bc_ur_dart/src/models/bch/bch_signature.dart';
export 'package:bc_ur_dart/src/models/btc/crypto_psbt_signature.dart';
export 'package:bc_ur_dart/src/models/btc/gspl_sign_request.dart';
export 'package:bc_ur_dart/src/models/btc/gspl_signature.dart';
export 'package:bc_ur_dart/src/models/btc/gspl_tx_data.dart';
export 'package:bc_ur_dart/src/models/btc/psbt_sign_request.dart';
export 'package:bc_ur_dart/src/models/btc/psbt_signature.dart';
export 'package:bc_ur_dart/src/models/common/fragment.dart';
export 'package:bc_ur_dart/src/models/common/seq.dart';
export 'package:bc_ur_dart/src/models/cosmos/cosmos_sign_request.dart';
export 'package:bc_ur_dart/src/models/cosmos/cosmos_signature.dart';
export 'package:bc_ur_dart/src/models/cosmos/keystone_cosmos_sign_request.dart';
export 'package:bc_ur_dart/src/models/cosmos/keystone_cosmos_signature.dart';
export 'package:bc_ur_dart/src/models/eth/eth_sign_request.dart';
export 'package:bc_ur_dart/src/models/eth/eth_signature.dart';
export 'package:bc_ur_dart/src/models/key/crypto_account.dart';
export 'package:bc_ur_dart/src/models/key/crypto_coin_info.dart';
export 'package:bc_ur_dart/src/models/key/crypto_hdkey.dart';
export 'package:bc_ur_dart/src/models/key/crypto_multi_accounts.dart';
export 'package:bc_ur_dart/src/models/sc/sc_sign_request.dart';
export 'package:bc_ur_dart/src/models/sc/sc_signature.dart';
export 'package:bc_ur_dart/src/models/sol/sol_sign_request.dart';
export 'package:bc_ur_dart/src/models/sol/sol_signature.dart';
export 'package:bc_ur_dart/src/models/sol/keystone_sol_sign_request.dart';
export 'package:bc_ur_dart/src/models/tron/keystone_tron_sign_request.dart';
export 'package:bc_ur_dart/src/models/tron/keystone_tron_sign_result.dart';
export 'package:bc_ur_dart/src/models/tron/tron_sign_request.dart';
export 'package:bc_ur_dart/src/models/tron/tron_signature.dart';
export 'package:bc_ur_dart/src/models/xrp/keystone_xrp_account_bytes.dart';
export 'package:bc_ur_dart/src/models/xrp/keystone_xrp_sign_request_bytes.dart';
export 'package:bc_ur_dart/src/models/xrp/keystone_xrp_signature_bytes.dart';
// Registry primitives and core UR transport.
// NOTE: src/registry/cbor_field_reader.dart is intentionally NOT exported — it is an
// internal model-decoding helper, not part of the stable public API.
export 'package:bc_ur_dart/src/registry/registry_type.dart';
export 'package:bc_ur_dart/src/registry/crypto_tx_entity.dart';
export 'package:bc_ur_dart/src/ur.dart';
export 'package:bc_ur_dart/src/utils/error.dart';
export 'package:bc_ur_dart/src/utils/type.dart';
export 'package:bc_ur_dart/src/utils/utils.dart';

// Compatibility re-exports retained for existing 0.x consumers.
// Avoid adding new third-party re-exports without a public API review.
export 'package:cbor/cbor.dart';
export 'package:crypto_wallet_util/crypto_utils.dart' show EthTxData, EthTxDataRaw, EthTxType, Eip1559TxData, Eip7702TxData, LegacyTxData, TxNetwork;
