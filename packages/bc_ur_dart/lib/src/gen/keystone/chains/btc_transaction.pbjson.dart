//
//  Generated code. Do not modify.
//  source: keystone/chains/btc_transaction.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use outputDescriptor instead')
const Output$json = {
  '1': 'Output',
  '2': [
    {'1': 'address', '3': 1, '4': 1, '5': 9, '10': 'address'},
    {'1': 'value', '3': 2, '4': 1, '5': 3, '10': 'value'},
    {'1': 'isChange', '3': 3, '4': 1, '5': 8, '10': 'isChange'},
    {'1': 'changeAddressPath', '3': 4, '4': 1, '5': 9, '10': 'changeAddressPath'},
  ],
};

/// Descriptor for `Output`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outputDescriptor = $convert.base64Decode(
    'CgZPdXRwdXQSGAoHYWRkcmVzcxgBIAEoCVIHYWRkcmVzcxIUCgV2YWx1ZRgCIAEoA1IFdmFsdW'
    'USGgoIaXNDaGFuZ2UYAyABKAhSCGlzQ2hhbmdlEiwKEWNoYW5nZUFkZHJlc3NQYXRoGAQgASgJ'
    'UhFjaGFuZ2VBZGRyZXNzUGF0aA==');

