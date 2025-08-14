///
import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use commitInfoDescriptor instead')
const CommitInfo$json = {
  '1': 'CommitInfo',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 3, '10': 'version'},
    {'1': 'store_infos', '3': 2, '4': 3, '5': 11, '6': '.cosmos.base.store.v1beta1.StoreInfo', '8': {}, '10': 'storeInfos'},
  ],
};

/// Descriptor for `CommitInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitInfoDescriptor = $convert.base64Decode('CgpDb21taXRJbmZvEhgKB3ZlcnNpb24YASABKANSB3ZlcnNpb24SSwoLc3RvcmVfaW5mb3MYAiADKAsyJC5jb3Ntb3MuYmFzZS5zdG9yZS52MWJldGExLlN0b3JlSW5mb0IEyN4fAFIKc3RvcmVJbmZvcw==');
@$core.Deprecated('Use storeInfoDescriptor instead')
const StoreInfo$json = {
  '1': 'StoreInfo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'commit_id', '3': 2, '4': 1, '5': 11, '6': '.cosmos.base.store.v1beta1.CommitID', '8': {}, '10': 'commitId'},
  ],
};

/// Descriptor for `StoreInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List storeInfoDescriptor = $convert.base64Decode('CglTdG9yZUluZm8SEgoEbmFtZRgBIAEoCVIEbmFtZRJGCgljb21taXRfaWQYAiABKAsyIy5jb3Ntb3MuYmFzZS5zdG9yZS52MWJldGExLkNvbW1pdElEQgTI3h8AUghjb21taXRJZA==');
@$core.Deprecated('Use commitIDDescriptor instead')
const CommitID$json = {
  '1': 'CommitID',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 3, '10': 'version'},
    {'1': 'hash', '3': 2, '4': 1, '5': 12, '10': 'hash'},
  ],
  '7': {},
};

/// Descriptor for `CommitID`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitIDDescriptor = $convert.base64Decode('CghDb21taXRJRBIYCgd2ZXJzaW9uGAEgASgDUgd2ZXJzaW9uEhIKBGhhc2gYAiABKAxSBGhhc2g6BJigHwA=');
