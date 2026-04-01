//
//  Generated code. Do not modify.
//  source: keystone/payload.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use payloadDescriptor instead')
const Payload$json = {
  '1': 'Payload',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.protoc.Payload.Type', '10': 'type'},
    {'1': 'xfp', '3': 2, '4': 1, '5': 9, '10': 'xfp'},
    {'1': 'signTx', '3': 4, '4': 1, '5': 11, '6': '.protoc.SignTransaction', '9': 0, '10': 'signTx'},
    {'1': 'signTxResult', '3': 7, '4': 1, '5': 11, '6': '.protoc.SignTransactionResult', '9': 0, '10': 'signTxResult'},
  ],
  '4': [Payload_Type$json],
  '8': [
    {'1': 'Content'},
  ],
};

@$core.Deprecated('Use payloadDescriptor instead')
const Payload_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'TYPE_RESERVE', '2': 0},
    {'1': 'TYPE_SIGN_TX', '2': 2},
    {'1': 'TYPE_SIGN_TX_RESULT', '2': 9},
  ],
};

/// Descriptor for `Payload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List payloadDescriptor = $convert.base64Decode(
    'CgdQYXlsb2FkEigKBHR5cGUYASABKA4yFC5wcm90b2MuUGF5bG9hZC5UeXBlUgR0eXBlEhAKA3'
    'hmcBgCIAEoCVIDeGZwEjEKBnNpZ25UeBgEIAEoCzIXLnByb3RvYy5TaWduVHJhbnNhY3Rpb25I'
    'AFIGc2lnblR4EkMKDHNpZ25UeFJlc3VsdBgHIAEoCzIdLnByb3RvYy5TaWduVHJhbnNhY3Rpb2'
    '5SZXN1bHRIAFIMc2lnblR4UmVzdWx0IkMKBFR5cGUSEAoMVFlQRV9SRVNFUlZFEAASEAoMVFlQ'
    'RV9TSUdOX1RYEAISFwoTVFlQRV9TSUdOX1RYX1JFU1VMVBAJQgkKB0NvbnRlbnQ=');

