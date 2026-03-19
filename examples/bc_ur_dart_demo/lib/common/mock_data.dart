/// 所有 UR 类型的 mock 参数，键名与 ur_encoder.dart 的 buildUR() 入参完全对应。
library;

const _kXfp = 'f23f9fd2';
const _kOrigin = 'bc_ur_dart demo';
const _kRequestId = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4';

// ─────────────────────────────────────────────────────────────
// SignRequest mock
// ─────────────────────────────────────────────────────────────

const kMockEthSignRequest = {
  'dataType': 'ETH_TRANSACTION_DATA',
  'address': '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6',
  'path': "m/44'/60'/0'/0/0",
  'xfp': _kXfp,
  'signData': '0xef8085012a05f20082520894742d35cc6634c0532925a3b8d4c9db96c4b4d8b6'
      '880de0b6b3a764000080018080',
  'chainId': '1',
  'origin': _kOrigin,
};

const kMockCosmosSignRequest = {
  'signData': '7b226163636f756e745f6e756d626572223a2231222c22636861696e5f6964223a22'
      '636f736d6f73687562222c22666565223a7b22616d6f756e74223a5b7b22616d6f75'
      '6e74223a2235303030222c2264656e6f6d223a227561746f6d227d5d7d7d',
  'path': "m/44'/118'/0'/0/0",
  'chain': 'cosmoshub',
  'xfp': _kXfp,
  'origin': _kOrigin,
  'fee': '5000',
};

const kMockSolSignRequest = {
  // Valid Solana transaction message format:
  // [header=01][sigCompact=00][blockhash32bytes][acctCompact=01][instrCompact=00]
  'signData': '01'  // header: 1 sig, 1 ro-signed, 1 ro-unsigned
      '00'  // 0 signatures (compact)
      '0000000000000000000000000000000000000000000000000000000000000000'  // blockhash
      '01'  // 1 account (compact)
      '0000000000000000000000000000000000000000000000000000000000000000'  // account
      '00',  // 0 instructions (compact)
  'signType': 'transaction',
  'path': "m/44'/501'/0'/0'",
  'xfp': _kXfp,
  'outputAddress': 'FDr2JQnmDRUNaX3qiuqwbQEbPoMPJScQi5VWgJJxVkAb',
  'origin': _kOrigin,
  'fee': '5000',
};

const kMockTronSignRequest = {
  'signData': '0a0208012208a1d4c9db96c4b4d8b640904e9af5052a5a0d0a0941746f6d73'
      '120454524f4e18a08d0622220a15415a523b449b1054b1443defe48cfb3a01'
      'a7bd3be1a15415a523b449b1054b1443defe48cfb3a01a7bd3be',
  'path': "m/44'/195'/0'/0/0",
  'xfp': _kXfp,
  'origin': _kOrigin,
  'fee': '100000',
};

const kMockAlphSignRequest = {
  'signData': '0000000000000000000000000000000000000000000000000000000000000001'
      '0001000000000000000000000000000000000000000000000000000000000001',
  'dataType': 'transaction',
  'path': "m/44'/1234'/0'/0/0",
  'xfp': _kXfp,
  'origin': _kOrigin,
  'outputs': [
    {'address': '1Ah7bWRzSg47VT1TqPfmrGHPHdvpFLnqdp', 'amount': '1000000'},
  ],
};

const kMockPsbtSignRequest = {
  'psbt': '70736274ff01009a020000000258e87a21b56daf0c23be8e7070456c336f7cbaa5c8757'
      '924f545887bb2abdd7500000000ffffffff838d0427d0ec650a68aa46bb0b098aea4422c'
      '071b2ca78352a077959d07cea1d0100000000ffffffff0270aaf00800000000160014d85'
      'c2b71d0060b09c9886aeb815e50991dda124d00e1f5050000000016001400aea9a2e5f0f'
      '876a588df5546e8742d1b657441000000',
  'path': "m/44'/0'/0'",
  'xfp': _kXfp,
  'origin': _kOrigin,
};

const kMockGsplSignRequest = {
  'hex': '0100000001a4c91916bdfba16cd79f9bb3a91e6a0fd49f1ec0a49c9f4ee4685abe5c5d'
      '5b0000000000ffffffff0280f0fa020000000017a914a0a08e43e3b4c1c25feeb13a26a'
      '9b0d2bb1a3ac68700e1f50500000000160014d85c2b71d0060b09c9886aeb815e50991d'
      'da124d00000000',
  'path': "m/44'/0'/0'/0/0",
  'xfp': _kXfp,
  'origin': _kOrigin,
  'inputs': [
    {
      'path': "m/44'/0'/0'/0/0",
      'address': '1A1zP1eP5QGefi2DMPTfTL5SLmv7Divf',
      'amount': '60000000',
    },
  ],
  'change': {
    'path': "m/44'/0'/0'/0/1",
    'address': '1CounterpartyXXXXXXXXXXXXXXXUWLpVr',
    'amount': '10000000',
  },
};

// ─────────────────────────────────────────────────────────────
// Signature mock（模拟硬件钱包返回）
// ─────────────────────────────────────────────────────────────

const kMockEthSignature = {
  'requestId': _kRequestId,
  'signature': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
      'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890'
      '1b',
  'origin': _kOrigin,
};

const kMockCosmosSignature = {
  'requestId': _kRequestId,
  'signature': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
      'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
  'origin': _kOrigin,
};

const kMockSolSignature = {
  'requestId': _kRequestId,
  'signature': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
      'abcdef1234567890abcdef1234567890abcdef1234567890abcdef12345678',
  'origin': _kOrigin,
};

const kMockTronSignature = {
  'requestId': _kRequestId,
  'signature': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
      'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890'
      '1c',
  'origin': _kOrigin,
};

const kMockAlphSignature = {
  'requestId': _kRequestId,
  'signature': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
      'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
  'origin': _kOrigin,
};

const kMockPsbtSignature = {
  'requestId': _kRequestId,
  'signature': '3045022100c6bd327ce8a7a7a8f20c9f0f7e0d7b23e52e91a4c8d0f6b7e3a2d1c8'
      'b5e4f3a2022051b3e8f9c7d2a4b6e1f0c3d5a8b2e7f4c1d9a6b3e0f5c2d4a7b1',
  'origin': _kOrigin,
};

const kMockGsplSignature = {
  'requestId': _kRequestId,
  'signedHex': '0100000001a4c91916bdfba16cd79f9bb3a91e6a0fd49f1ec0a49c9f4ee4685abe5c'
      '5d5b00000000484730440220c6bd327ce8a7a7a8f20c9f0f7e0d7b23e52e91a4c8d0'
      'f6b7e3a2d1c8b5e4f3a202201234567890abcdef01ffffffff0280f0fa020000000017'
      'a914a0a08e43e3b4c1c25feeb13a26a9b0d2bb1a3ac68700e1f50500000000160014d'
      '85c2b71d0060b09c9886aeb815e50991dda124d00000000',
  'origin': _kOrigin,
};

// ─────────────────────────────────────────────────────────────
// 账户类 mock
// ─────────────────────────────────────────────────────────────

const kMockCryptoHDKey = {
  'xpub': 'xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu'
      '24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB',
  'path': "m/44'/60'/0'",
  'name': 'FxWallet Demo',
  'xfp': _kXfp,
};

const kMockCryptoMultiAccounts = {
  'masterFingerprint': _kXfp,
  'device': 'FxWallet',
  'walletName': 'Demo Wallet',
  'chains': [
    {
      'path': "m/44'/60'/0'",
      'chains': ['ETH'],
      'xpub': 'xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu'
          '24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB',
    },
    {
      'path': "m/44'/0'/0'",
      'chains': ['BTC'],
      'xpub': 'xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu'
          '24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB',
    },
  ],
};

// ─────────────────────────────────────────────────────────────
// 注册表：type → mock
// ─────────────────────────────────────────────────────────────

const Map<String, Map<String, dynamic>> kMockByType = {
  // SignRequest
  'eth-sign-request': kMockEthSignRequest,
  'cosmos-sign-request': kMockCosmosSignRequest,
  'sol-sign-request': kMockSolSignRequest,
  'tron-sign-request': kMockTronSignRequest,
  'alph-sign-request': kMockAlphSignRequest,
  'psbt-sign-request': kMockPsbtSignRequest,
  'btc-sign-request': kMockGsplSignRequest,
  // Signature
  'eth-signature': kMockEthSignature,
  'cosmos-signature': kMockCosmosSignature,
  'sol-signature': kMockSolSignature,
  'tron-signature': kMockTronSignature,
  'alph-signature': kMockAlphSignature,
  'psbt-signature': kMockPsbtSignature,
  'btc-signature': kMockGsplSignature,
  // Account
  'crypto-hdkey': kMockCryptoHDKey,
  'crypto-multi-accounts': kMockCryptoMultiAccounts,
};
