/// UR 类型的元数据配置：字段列表 + 字段类型，供动态表单渲染使用。
library;

// 字段渲染类型
enum FieldType {
  text,      // 普通字符串
  hex,       // 十六进制（显示 0x 前缀提示）
  path,      // BIP44 路径
  address,   // 链上地址
  integer,   // 数字
  dropdown,  // 枚举选项
  jsonList,  // JSON 数组（outputs / inputs / chains）
  jsonMap,   // JSON 对象（change）
  xpub,      // BIP32 扩展公钥
  chainList, // crypto-multi-accounts 的 chains 动态列表
}

class FieldConfig {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options; // dropdown 选项
  final String? hint;

  const FieldConfig({
    required this.key,
    required this.label,
    required this.type,
    this.required = true,
    this.options,
    this.hint,
  });
}

class UrTypeConfig {
  final String type;       // UR type string
  final String label;      // 显示名称
  final String group;      // 分组
  final bool isSignRequest; // 是否为签名流程入口
  final List<FieldConfig> fields;

  const UrTypeConfig({
    required this.type,
    required this.label,
    required this.group,
    required this.fields,
    this.isSignRequest = false,
  });
}

// ─────────────────────────────────────────────────────────────
// 所有类型配置
// ─────────────────────────────────────────────────────────────

const List<UrTypeConfig> kUrTypeConfigs = [
  // ── ETH ──────────────────────────────────────────────────
  UrTypeConfig(
    type: 'eth-sign-request',
    label: 'ETH Sign Request',
    group: 'Ethereum',
    isSignRequest: true,
    fields: [
      FieldConfig(key: 'dataType', label: 'Data Type', type: FieldType.dropdown, 
          options: ['ETH_TRANSACTION_DATA', 'ETH_TYPED_DATA', 'ETH_RAW_BYTES', 'ETH_TYPED_TRANSACTION']),
      FieldConfig(key: 'signData', label: 'Sign Data (hex)', type: FieldType.hex,
          hint: 'Complete RLP-encoded transaction hex, or message hex'),
      FieldConfig(key: 'address', label: 'Address', type: FieldType.address),
      FieldConfig(key: 'path', label: 'Derivation Path', type: FieldType.path),
      FieldConfig(key: 'xfp', label: 'Master Fingerprint', type: FieldType.hex,
          hint: '4 bytes, e.g. f23f9fd2'),
      FieldConfig(key: 'chainId', label: 'Chain ID', type: FieldType.integer,
          hint: '1=Mainnet, 5=Goerli'),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── Cosmos ────────────────────────────────────────────────
  UrTypeConfig(
    type: 'cosmos-sign-request',
    label: 'Cosmos Sign Request',
    group: 'Cosmos',
    isSignRequest: true,
    fields: [
      FieldConfig(key: 'signData', label: 'Sign Data (hex)', type: FieldType.hex),
      FieldConfig(key: 'chain', label: 'Chain ID', type: FieldType.text,
          hint: 'e.g. cosmoshub, osmosis'),
      FieldConfig(key: 'path', label: 'Derivation Path', type: FieldType.path),
      FieldConfig(key: 'xfp', label: 'Master Fingerprint', type: FieldType.hex),
      FieldConfig(key: 'fee', label: 'Fee (uatom)', type: FieldType.integer, required: false,
        hint: 'e.g. 1000 or 0x3e8',
      ),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── Solana ────────────────────────────────────────────────
  UrTypeConfig(
    type: 'sol-sign-request',
    label: 'Solana Sign Request',
    group: 'Solana',
    isSignRequest: true,
    fields: [
      FieldConfig(key: 'signType', label: 'Sign Type', type: FieldType.dropdown, options: ['transaction', 'message']),
      FieldConfig(key: 'signData', label: 'Sign Data (hex)', type: FieldType.hex),
      FieldConfig(key: 'path', label: 'Derivation Path', type: FieldType.path),
      FieldConfig(key: 'xfp', label: 'Master Fingerprint', type: FieldType.hex),
      FieldConfig(key: 'outputAddress', label: 'Output Address', type: FieldType.address,
          required: false),
      FieldConfig(key: 'contractAddress', label: 'Contract Address', type: FieldType.address,
          required: false),
      FieldConfig(key: 'fee', label: 'Fee (lamports)', type: FieldType.integer, required: false),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── Tron ──────────────────────────────────────────────────
  UrTypeConfig(
    type: 'tron-sign-request',
    label: 'Tron Sign Request',
    group: 'Tron',
    isSignRequest: true,
    fields: [
      FieldConfig(key: 'signData', label: 'Sign Data (hex)', type: FieldType.hex),
      FieldConfig(key: 'path', label: 'Derivation Path', type: FieldType.path),
      FieldConfig(key: 'xfp', label: 'Master Fingerprint', type: FieldType.hex),
      FieldConfig(key: 'fee', label: 'Fee (sun)', type: FieldType.integer, required: false,
        hint: 'e.g. 1000 or 0x3e8',
      ),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── Alph ──────────────────────────────────────────────────
  UrTypeConfig(
    type: 'alph-sign-request',
    label: 'ALPH Sign Request',
    group: 'Alephium',
    isSignRequest: true,
    fields: [
      FieldConfig(key: 'signData', label: 'Sign Data (hex)', type: FieldType.hex),
      FieldConfig(key: 'path', label: 'Derivation Path', type: FieldType.path),
      FieldConfig(key: 'xfp', label: 'Master Fingerprint', type: FieldType.hex),
      FieldConfig(key: 'dataType', label: 'Data Type', type: FieldType.dropdown, options: ['transaction', 'message']),
      FieldConfig(key: 'outputs', label: 'Outputs (JSON)', type: FieldType.jsonList,
          required: false,
          hint: '[{"address":"...","amount":"1000000"}]'),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── PSBT ──────────────────────────────────────────────────
  UrTypeConfig(
    type: 'psbt-sign-request',
    label: 'PSBT Sign Request',
    group: 'Bitcoin',
    isSignRequest: true,
    fields: [
      FieldConfig(key: 'psbt', label: 'PSBT (hex)', type: FieldType.hex,
          hint: 'Partially Signed Bitcoin Transaction hex'),
      FieldConfig(key: 'path', label: 'Derivation Path', type: FieldType.path),
      FieldConfig(key: 'xfp', label: 'Master Fingerprint', type: FieldType.hex),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── GSPL ──────────────────────────────────────────────────
  UrTypeConfig(
    type: 'btc-sign-request',
    label: 'GSPL Sign Request',
    group: 'Bitcoin',
    isSignRequest: true,
    fields: [
      FieldConfig(key: 'hex', label: 'Raw TX Hex', type: FieldType.hex),
      FieldConfig(key: 'path', label: 'Derivation Path', type: FieldType.path),
      FieldConfig(key: 'xfp', label: 'Master Fingerprint', type: FieldType.hex),
      FieldConfig(key: 'inputs', label: 'Inputs (JSON)', type: FieldType.jsonList,
          hint: '[{"path":"m/44\'/0\'...","address":"1A...","amount":"60000000"}]'),
      FieldConfig(key: 'change', label: 'Change (JSON)', type: FieldType.jsonMap,
          required: false,
          hint: '{"path":"m/44\'/0\'...","address":"1C...","amount":"10000000"}'),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── ETH Signature ─────────────────────────────────────────
  UrTypeConfig(
    type: 'eth-signature',
    label: 'ETH Signature',
    group: 'Ethereum',
    fields: [
      FieldConfig(key: 'requestId', label: 'Request ID (hex)', type: FieldType.hex, hint: 'UUID from SignRequest, 16 bytes hex'),
      FieldConfig(key: 'signature', label: 'Signature (hex)', type: FieldType.hex, hint: 'r(32) + s(32) + v(1) = 65 bytes'),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── Cosmos Signature ──────────────────────────────────────
  UrTypeConfig(
    type: 'cosmos-signature',
    label: 'Cosmos Signature',
    group: 'Cosmos',
    fields: [
      FieldConfig(key: 'requestId', label: 'Request ID (hex)', type: FieldType.hex),
      FieldConfig(key: 'signature', label: 'Signature (hex)', type: FieldType.hex),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── Solana Signature ──────────────────────────────────────
  UrTypeConfig(
    type: 'sol-signature',
    label: 'Solana Signature',
    group: 'Solana',
    fields: [
      FieldConfig(key: 'requestId', label: 'Request ID (hex)', type: FieldType.hex),
      FieldConfig(key: 'signature', label: 'Signature (hex)', type: FieldType.hex, hint: '64 bytes Ed25519 signature'),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── Tron Signature ────────────────────────────────────────
  UrTypeConfig(
    type: 'tron-signature',
    label: 'Tron Signature',
    group: 'Tron',
    fields: [
      FieldConfig(key: 'requestId', label: 'Request ID (hex)', type: FieldType.hex, required: false, hint: 'Tron allows omitting requestId'),
      FieldConfig(key: 'signature', label: 'Signature (hex)', type: FieldType.hex),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── Alph Signature ────────────────────────────────────────
  UrTypeConfig(
    type: 'alph-signature',
    label: 'ALPH Signature',
    group: 'Alephium',
    fields: [
      FieldConfig(key: 'requestId', label: 'Request ID (hex)', type: FieldType.hex),
      FieldConfig(key: 'signature', label: 'Signature (hex)', type: FieldType.hex),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── PSBT Signature ────────────────────────────────────────
  UrTypeConfig(
    type: 'psbt-signature',
    label: 'PSBT Signature',
    group: 'Bitcoin',
    fields: [
      FieldConfig(key: 'requestId', label: 'Request ID (hex)', type: FieldType.hex),
      FieldConfig(key: 'signature', label: 'Signature (hex)', type: FieldType.hex, hint: 'DER-encoded signature hex'),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),

  // ── GSPL Signature ────────────────────────────────────────
  UrTypeConfig(
    type: 'btc-signature',
    label: 'GSPL Signature',
    group: 'Bitcoin',
    fields: [
      FieldConfig(key: 'requestId', label: 'Request ID (hex)', type: FieldType.hex),
      FieldConfig(key: 'signedHex', label: 'Signed TX Hex', type: FieldType.hex, hint: 'Complete signed BTC transaction hex'),
      FieldConfig(key: 'origin', label: 'Origin', type: FieldType.text, required: false),
    ],
  ),


  // ── HD Key ────────────────────────────────────────────────
  UrTypeConfig(
    type: 'crypto-hdkey',
    label: 'Crypto HD Key',
    group: 'Account',
    fields: [
      FieldConfig(key: 'xpub', label: 'Extended Public Key (xpub)', type: FieldType.xpub),
      FieldConfig(key: 'path', label: 'Derivation Path', type: FieldType.path),
      FieldConfig(key: 'name', label: 'Wallet Name', type: FieldType.text),
      FieldConfig(key: 'xfp', label: 'Master Fingerprint', type: FieldType.hex,
          required: false),
    ],
  ),

  // ── Multi Accounts ────────────────────────────────────────
  UrTypeConfig(
    type: 'crypto-multi-accounts',
    label: 'Crypto Multi Accounts',
    group: 'Account',
    fields: [
      FieldConfig(key: 'masterFingerprint', label: 'Master Fingerprint', type: FieldType.hex),
      FieldConfig(key: 'device', label: 'Device Name', type: FieldType.text),
      FieldConfig(key: 'walletName', label: 'Wallet Name', type: FieldType.text),
      FieldConfig(key: 'chains', label: 'Chains', type: FieldType.chainList),
    ],
  ),
];

// 按 group 分组
Map<String, List<UrTypeConfig>> get kUrTypesByGroup {
  final result = <String, List<UrTypeConfig>>{};
  for (final config in kUrTypeConfigs) {
    result.putIfAbsent(config.group, () => []).add(config);
  }
  return result;
}

// 按 type 字符串快速查找
UrTypeConfig? findConfig(String type) {
  try {
    return kUrTypeConfigs.firstWhere((c) => c.type == type.toLowerCase());
  } catch (_) {
    return null;
  }
}
