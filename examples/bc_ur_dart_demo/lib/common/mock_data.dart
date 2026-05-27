/// 所有 UR 类型的 mock 参数，键名与 ur_encoder.dart 的 buildUR() 入参完全对应。
library;

const _kXfp = 'f23f9fd2';
const _kOrigin = 'bc_ur_dart demo';
const _kRequestId = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4';

/// EIP7702 演示用测试私钥 (32 字节 hex)
/// ⚠️ 仅用于演示用途，不要用于生产环境
const _kTestPrivKey = '0x' + 'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

// ─────────────────────────────────────────────────────────────
// SignRequest mock
// ─────────────────────────────────────────────────────────────

const kMockEthSignRequest = {
  'dataType': 'ETH_TRANSACTION_DATA',
  'txType': 'eip7702', // 默认 EIP7702 交易模式
  'address': '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6',
  'to': '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6',
  'value': '1000000000000000000', // 1 ETH in wei
  'nonce': '0',
  'gasLimit': '21000',
  'maxFee': '20000000000', // 20 gwei
  'maxPriority': '2000000000', // 2 gwei
  'data': '0x',
  'path': "m/44'/60'/0'/0/0",
  'xfp': _kXfp,
  'chainId': '1',
  'origin': _kOrigin,
  'eip7702Contract': '0x0000000000000000000000000000000000000000',
  '_testPrivKey': _kTestPrivKey,
  'signData': '0xef8085012a05f20082520894742d35cc6634c0532925a3b8d4c9db96c4b4d8b6'
      '880de0b6b3a764000080018080',
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
  'signData': '01' // header: 1 sig, 1 ro-signed, 1 ro-unsigned
      '00' // 0 signatures (compact)
      '0000000000000000000000000000000000000000000000000000000000000000' // blockhash
      '01' // 1 account (compact)
      '0000000000000000000000000000000000000000000000000000000000000000' // account
      '00', // 0 instructions (compact)
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

const kMockBchSignRequest = {
  'requestId': 'bch-request-id',
  'xfp': _kXfp,
  'hdPath': "m/44'/145'/0'",
  'origin': _kOrigin,
  'fee': '500',
  'inputs': [
    {
      'hash': '4d3c2b1a09080706050403020100ffeeddccbbaa99887766554433221100ffeeddcc',
      'index': 0,
      'value': '100000',
      'pubkey': '02c6047f9441ed7d6d3045406e95c07cd85a2d2a3d1e73d0b8f8f0d6d4a86f8f6a',
      'ownerKeyPath': "m/44'/145'/0'/0/0",
    },
  ],
  'outputs': [
    {
      'address': 'bitcoincash:qq07g6kz8zqauyn9f0rqpxnrsyvz2xy3xqyqj8xq2n',
      'value': '99500',
      'isChange': false,
    },
  ],
};

const kMockKeystoneCosmosSignRequest = {
  'dataType': 'amino',
  'signDataHex': '7b22636861696e5f6964223a22636f736d6f736875622d34227d',
  'path': "m/44'/118'/0'/0/0",
  'xfp': _kXfp,
  'address': 'cosmos1qnk2n4nlkpw9xfqntladh74er2xa62wgas5vdz',
  'origin': _kOrigin,
};

const kMockKeystoneSolSignRequest = {
  'signType': 'transaction',
  'signDataHex': 'deadbeef01020304',
  'path': "m/44'/501'/0'/0'",
  'xfp': _kXfp,
  'address': 'FDr2JQnmDRUNaX3qiuqwbQEbPoMPJScQi5VWgJJxVkAb',
  'origin': _kOrigin,
};

const kMockKeystoneTronSignRequest = {
  'requestId': 'trx-request-id',
  'signDataHex': '0a0232202208dd448d6e1f3946c540c8d2f9f082315a67080112630a2d74797065'
      '2e676f6f676c65617069732e636f6d2f70726f746f636f6c2e5472616e73666572436f'
      '6e747261637412320a1541a9569efd62152d36adbd577a9bc6deab09d0d462121541'
      '2a4d2fe3ce100a12b1626aa5aab8393d2e60a13c18c0843d70fe96f6f08231',
  'path': "m/44'/195'/0'",
  'xfp': '21d0ae26',
  'origin': _kOrigin,
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

const kMockCryptoPsbt = {
  'signature': '70736274ff01009a020000000258e87a21b56daf0c23be8e7070456c336f7cbaa5c8757'
      '924f545887bb2abdd7500000000ffffffff838d0427d0ec650a68aa46bb0b098aea4422c'
      '071b2ca78352a077959d07cea1d0100000000ffffffff0270aaf00800000000160014d85'
      'c2b71d0060b09c9886aeb815e50991dda124d00e1f5050000000016001400aea9a2e5f0f'
      '876a588df5546e8742d1b657441000000',
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

const kMockBchSignature = {
  'requestId': 'bch-request-id',
  'rawTx': '0100000001ccddeeff00112233445566778899aabbccddeeff000102030405060708090a1b2c3d'
      '4d000000006a47304402201234567890abcdef1234567890abcdef1234567890abcdef123456'
      '7890abcdef02201234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
      '412102c6047f9441ed7d6d3045406e95c07cd85a2d2a3d1e73d0b8f8f0d6d4a86f8f6affffffff'
      '01ac850100000000001976a91400112233445566778899aabbccddeeff0011223388ac00000000',
};

const kMockKeystoneTronSignResult = {
  'requestId': 'trx-request-id',
  'txId': '0x1234abcd',
  'rawTx': '0xdeadbeefcafe',
};

const kMockXrpSignRequest = {
  'transaction': {
    'Account': 'rSource',
    'TransactionType': 'Payment',
    'Destination': 'rDest',
    'Amount': '1000',
  },
};

const kMockXrpSignature = {
  'signature': 'ABC123',
  'publicKey': '02ABCD',
  'signedBlob': '120000228000000024000000012E0000000C6140000000000003E8',
  'txHash': 'DEADBEEF',
};

const kMockXrpAccount = {
  'address': 'rAccount',
  'publicKey': '02ABCD',
};

// ─────────────────────────────────────────────────────────────
// 账户类 mock
// ─────────────────────────────────────────────────────────────

const kMockCryptoHDKey = {
  'path': "m/44'/60'/0'",
  'childrenPath': '0/*',
  'sourceFingerprint': '21d0ae26',
  'xfp': '21d0ae26',
  'xfpFormat': 'canonical',
  'xpub': 'xpub6BxsQ7ydwv2jJdLfcyHkgViz7GzFRSxvnCRvnXezMoxsMNvfoQYyHtEcW5r9X3wh7Q3nomYt4rV7E2yLU7S161ZHT83W5nUxEGKqSd3aXo4',
  'publicKey': '03d0f77d063d2c645803dcf7c203a9bafb9af221ffd95777d6d61b3b4d6b390224',
  'chainCode': '9bdef1bfdaebd9f35327f20cae76e76f62cc687e8f38d93cb2d7a160d638834c',
  'name': 'Keystone',
  'note': 'account.standard',
};

const kMockCryptoMultiAccounts = {
  'masterFingerprint': '21d0ae26',
  'device': 'Keystone 3 Pro',
  'deviceId': '5d4a7f01b9225db8d1f510e0ee682c47b0c585d1',
  'version': '2.0.4',
  'walletName': '',
  'xfpFormat': 'canonical',
  'chains': [
    {
      'path': "m/44'/60'/0'",
      'childrenPath': '0/*',
      'sourceFingerprint': '21d0ae26',
      'xfpFormat': 'canonical',
      'xpub': 'xpub6BxsQ7ydwv2jJdLfcyHkgViz7GzFRSxvnCRvnXezMoxsMNvfoQYyHtEcW5r9X3wh7Q3nomYt4rV7E2yLU7S161ZHT83W5nUxEGKqSd3aXo4',
      'publicKey': '03d0f77d063d2c645803dcf7c203a9bafb9af221ffd95777d6d61b3b4d6b390224',
      'chainCode': '9bdef1bfdaebd9f35327f20cae76e76f62cc687e8f38d93cb2d7a160d638834c',
      'name': 'Keystone',
      'note': 'account.standard',
    },
    {
      'path': "m/44'/60'/0'/0",
      'childrenPath': '',
      'sourceFingerprint': '21d0ae26',
      'xfpFormat': 'canonical',
      'xpub': '',
      'publicKey': '03bbc64f4b1a2b16c3539e71963dec71435f3065d6b0f36c8ae4762f1203416c6d',
      'chainCode': '',
      'name': 'Keystone',
      'note': 'account.ledger_legacy',
    },
    {
      'path': "m/44'/60'/0'/0/0",
      'childrenPath': '',
      'sourceFingerprint': '21d0ae26',
      'xfpFormat': 'canonical',
      'xpub': '',
      'publicKey': '038e047b017db4fce26fd07f2cdcc26c39a0742e6fd8936932557367b68cc9c814',
      'chainCode': '',
      'name': 'Keystone',
      'note': 'account.ledger_live',
    },
  ],
};

const kMockCryptoAccount = {
  'masterFingerprint': '21d0ae26',
  'xfpFormat': 'canonical',
  'outputs': [
    {
      'path': "m/44'/60'/0'",
      'childrenPath': '0/*',
      'sourceFingerprint': '21d0ae26',
      'xfpFormat': 'canonical',
      'xpub': 'xpub6BxsQ7ydwv2jJdLfcyHkgViz7GzFRSxvnCRvnXezMoxsMNvfoQYyHtEcW5r9X3wh7Q3nomYt4rV7E2yLU7S161ZHT83W5nUxEGKqSd3aXo4',
      'publicKey': '03d0f77d063d2c645803dcf7c203a9bafb9af221ffd95777d6d61b3b4d6b390224',
      'chainCode': '9bdef1bfdaebd9f35327f20cae76e76f62cc687e8f38d93cb2d7a160d638834c',
      'name': 'Keystone',
      'note': 'account.standard',
    },
    {
      'path': "m/84'/0'/0'",
      'childrenPath': '0/*',
      'sourceFingerprint': '21d0ae26',
      'xfpFormat': 'canonical',
      'xpub': '',
      'publicKey': '02bbc64f4b1a2b16c3539e71963dec71435f3065d6b0f36c8ae4762f1203416c6d',
      'chainCode': '7bdef1bfdaebd9f35327f20cae76e76f62cc687e8f38d93cb2d7a160d638834d',
      'name': 'Keystone',
      'note': 'bitcoin.native_segwit',
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
  'bch-sign-request': kMockBchSignRequest,
  'keystone-cosmos-sign-request': kMockKeystoneCosmosSignRequest,
  'keystone-sol-sign-request': kMockKeystoneSolSignRequest,
  'keystone-tron-sign-request': kMockKeystoneTronSignRequest,
  // Signature
  'eth-signature': kMockEthSignature,
  'cosmos-signature': kMockCosmosSignature,
  'sol-signature': kMockSolSignature,
  'tron-signature': kMockTronSignature,
  'alph-signature': kMockAlphSignature,
  'psbt-signature': kMockPsbtSignature,
  'crypto-psbt': kMockCryptoPsbt,
  'btc-signature': kMockGsplSignature,
  'bch-signature': kMockBchSignature,
  'keystone-tron-sign-result': kMockKeystoneTronSignResult,
  'xrp-signature': kMockXrpSignature,
  'xrp-sign-request': kMockXrpSignRequest,
  'xrp-account': kMockXrpAccount,
  // Account
  'crypto-hdkey': kMockCryptoHDKey,
  'crypto-account': kMockCryptoAccount,
  'crypto-multi-accounts': kMockCryptoMultiAccounts,
};
