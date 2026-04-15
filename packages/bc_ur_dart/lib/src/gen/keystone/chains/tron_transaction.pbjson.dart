//
//  Generated code. Do not modify.
//  source: keystone/chains/tron_transaction.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use latestBlockDescriptor instead')
const LatestBlock$json = {
  '1': 'LatestBlock',
  '2': [
    {'1': 'hash', '3': 1, '4': 1, '5': 9, '10': 'hash'},
    {'1': 'number', '3': 2, '4': 1, '5': 5, '10': 'number'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `LatestBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List latestBlockDescriptor = $convert.base64Decode(
    'CgtMYXRlc3RCbG9jaxISCgRoYXNoGAEgASgJUgRoYXNoEhYKBm51bWJlchgCIAEoBVIGbnVtYm'
    'VyEhwKCXRpbWVzdGFtcBgDIAEoA1IJdGltZXN0YW1w');

@$core.Deprecated('Use overrideDescriptor instead')
const Override$json = {
  '1': 'Override',
  '2': [
    {'1': 'tokenShortName', '3': 1, '4': 1, '5': 9, '10': 'tokenShortName'},
    {'1': 'tokenFullName', '3': 2, '4': 1, '5': 9, '10': 'tokenFullName'},
    {'1': 'decimals', '3': 3, '4': 1, '5': 5, '10': 'decimals'},
  ],
};

/// Descriptor for `Override`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List overrideDescriptor = $convert.base64Decode(
    'CghPdmVycmlkZRImCg50b2tlblNob3J0TmFtZRgBIAEoCVIOdG9rZW5TaG9ydE5hbWUSJAoNdG'
    '9rZW5GdWxsTmFtZRgCIAEoCVINdG9rZW5GdWxsTmFtZRIaCghkZWNpbWFscxgDIAEoBVIIZGVj'
    'aW1hbHM=');

@$core.Deprecated('Use tronTxDescriptor instead')
const TronTx$json = {
  '1': 'TronTx',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'contractAddress', '3': 2, '4': 1, '5': 9, '10': 'contractAddress'},
    {'1': 'from', '3': 3, '4': 1, '5': 9, '10': 'from'},
    {'1': 'to', '3': 4, '4': 1, '5': 9, '10': 'to'},
    {'1': 'memo', '3': 5, '4': 1, '5': 9, '10': 'memo'},
    {'1': 'value', '3': 6, '4': 1, '5': 9, '10': 'value'},
    {'1': 'latestBlock', '3': 7, '4': 1, '5': 11, '6': '.protoc.LatestBlock', '10': 'latestBlock'},
    {'1': 'override', '3': 8, '4': 1, '5': 11, '6': '.protoc.Override', '10': 'override'},
    {'1': 'fee', '3': 9, '4': 1, '5': 5, '10': 'fee'},
  ],
};

/// Descriptor for `TronTx`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tronTxDescriptor = $convert.base64Decode(
    'CgZUcm9uVHgSFAoFdG9rZW4YASABKAlSBXRva2VuEigKD2NvbnRyYWN0QWRkcmVzcxgCIAEoCV'
    'IPY29udHJhY3RBZGRyZXNzEhIKBGZyb20YAyABKAlSBGZyb20SDgoCdG8YBCABKAlSAnRvEhIK'
    'BG1lbW8YBSABKAlSBG1lbW8SFAoFdmFsdWUYBiABKAlSBXZhbHVlEjUKC2xhdGVzdEJsb2NrGA'
    'cgASgLMhMucHJvdG9jLkxhdGVzdEJsb2NrUgtsYXRlc3RCbG9jaxIsCghvdmVycmlkZRgIIAEo'
    'CzIQLnByb3RvYy5PdmVycmlkZVIIb3ZlcnJpZGUSEAoDZmVlGAkgASgFUgNmZWU=');

