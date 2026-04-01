//
//  Generated code. Do not modify.
//  source: keystone/sign_transaction_result.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use signTransactionResultDescriptor instead')
const SignTransactionResult$json = {
  '1': 'SignTransactionResult',
  '2': [
    {'1': 'signId', '3': 1, '4': 1, '5': 9, '10': 'signId'},
    {'1': 'txId', '3': 2, '4': 1, '5': 9, '10': 'txId'},
    {'1': 'rawTx', '3': 3, '4': 1, '5': 9, '10': 'rawTx'},
  ],
};

/// Descriptor for `SignTransactionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signTransactionResultDescriptor = $convert.base64Decode(
    'ChVTaWduVHJhbnNhY3Rpb25SZXN1bHQSFgoGc2lnbklkGAEgASgJUgZzaWduSWQSEgoEdHhJZB'
    'gCIAEoCVIEdHhJZBIUCgVyYXdUeBgDIAEoCVIFcmF3VHg=');

