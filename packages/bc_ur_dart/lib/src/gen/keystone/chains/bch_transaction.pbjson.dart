//
//  Generated code. Do not modify.
//  source: keystone/chains/bch_transaction.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use bchTxDescriptor instead')
const BchTx$json = {
  '1': 'BchTx',
  '2': [
    {'1': 'fee', '3': 1, '4': 1, '5': 3, '10': 'fee'},
    {'1': 'dustThreshold', '3': 2, '4': 1, '5': 5, '10': 'dustThreshold'},
    {'1': 'memo', '3': 3, '4': 1, '5': 9, '10': 'memo'},
    {'1': 'inputs', '3': 4, '4': 3, '5': 11, '6': '.protoc.BchTx.Input', '10': 'inputs'},
    {'1': 'outputs', '3': 5, '4': 3, '5': 11, '6': '.protoc.Output', '10': 'outputs'},
  ],
  '3': [BchTx_Input$json],
};

@$core.Deprecated('Use bchTxDescriptor instead')
const BchTx_Input$json = {
  '1': 'Input',
  '2': [
    {'1': 'hash', '3': 1, '4': 1, '5': 9, '10': 'hash'},
    {'1': 'index', '3': 2, '4': 1, '5': 5, '10': 'index'},
    {'1': 'value', '3': 3, '4': 1, '5': 3, '10': 'value'},
    {'1': 'pubkey', '3': 4, '4': 1, '5': 9, '10': 'pubkey'},
    {'1': 'ownerKeyPath', '3': 5, '4': 1, '5': 9, '10': 'ownerKeyPath'},
  ],
};

/// Descriptor for `BchTx`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bchTxDescriptor = $convert.base64Decode(
    'CgVCY2hUeBIQCgNmZWUYASABKANSA2ZlZRIkCg1kdXN0VGhyZXNob2xkGAIgASgFUg1kdXN0VG'
    'hyZXNob2xkEhIKBG1lbW8YAyABKAlSBG1lbW8SKwoGaW5wdXRzGAQgAygLMhMucHJvdG9jLkJj'
    'aFR4LklucHV0UgZpbnB1dHMSKAoHb3V0cHV0cxgFIAMoCzIOLnByb3RvYy5PdXRwdXRSB291dH'
    'B1dHMagwEKBUlucHV0EhIKBGhhc2gYASABKAlSBGhhc2gSFAoFaW5kZXgYAiABKAVSBWluZGV4'
    'EhQKBXZhbHVlGAMgASgDUgV2YWx1ZRIWCgZwdWJrZXkYBCABKAlSBnB1YmtleRIiCgxvd25lck'
    'tleVBhdGgYBSABKAlSDG93bmVyS2V5UGF0aA==');

