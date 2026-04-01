//
//  Generated code. Do not modify.
//  source: keystone/transaction.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use signTransactionDescriptor instead')
const SignTransaction$json = {
  '1': 'SignTransaction',
  '2': [
    {'1': 'coinCode', '3': 1, '4': 1, '5': 9, '10': 'coinCode'},
    {'1': 'signId', '3': 2, '4': 1, '5': 9, '10': 'signId'},
    {'1': 'hdPath', '3': 3, '4': 1, '5': 9, '10': 'hdPath'},
    {'1': 'timestamp', '3': 4, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'decimal', '3': 5, '4': 1, '5': 5, '10': 'decimal'},
    {'1': 'bchTx', '3': 10, '4': 1, '5': 11, '6': '.protoc.BchTx', '9': 0, '10': 'bchTx'},
  ],
  '8': [
    {'1': 'Transaction'},
  ],
};

/// Descriptor for `SignTransaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signTransactionDescriptor = $convert.base64Decode(
    'Cg9TaWduVHJhbnNhY3Rpb24SGgoIY29pbkNvZGUYASABKAlSCGNvaW5Db2RlEhYKBnNpZ25JZB'
    'gCIAEoCVIGc2lnbklkEhYKBmhkUGF0aBgDIAEoCVIGaGRQYXRoEhwKCXRpbWVzdGFtcBgEIAEo'
    'A1IJdGltZXN0YW1wEhgKB2RlY2ltYWwYBSABKAVSB2RlY2ltYWwSJQoFYmNoVHgYCiABKAsyDS'
    '5wcm90b2MuQmNoVHhIAFIFYmNoVHhCDQoLVHJhbnNhY3Rpb24=');

