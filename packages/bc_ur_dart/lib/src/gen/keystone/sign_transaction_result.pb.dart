//
//  Generated code. Do not modify.
//  source: keystone/sign_transaction_result.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SignTransactionResult extends $pb.GeneratedMessage {
  factory SignTransactionResult({
    $core.String? signId,
    $core.String? txId,
    $core.String? rawTx,
  }) {
    final $result = create();
    if (signId != null) {
      $result.signId = signId;
    }
    if (txId != null) {
      $result.txId = txId;
    }
    if (rawTx != null) {
      $result.rawTx = rawTx;
    }
    return $result;
  }
  SignTransactionResult._() : super();
  factory SignTransactionResult.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SignTransactionResult.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SignTransactionResult', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'signId', protoName: 'signId')
    ..aOS(2, _omitFieldNames ? '' : 'txId', protoName: 'txId')
    ..aOS(3, _omitFieldNames ? '' : 'rawTx', protoName: 'rawTx')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SignTransactionResult clone() => SignTransactionResult()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SignTransactionResult copyWith(void Function(SignTransactionResult) updates) => super.copyWith((message) => updates(message as SignTransactionResult)) as SignTransactionResult;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignTransactionResult create() => SignTransactionResult._();
  SignTransactionResult createEmptyInstance() => create();
  static $pb.PbList<SignTransactionResult> createRepeated() => $pb.PbList<SignTransactionResult>();
  @$core.pragma('dart2js:noInline')
  static SignTransactionResult getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SignTransactionResult>(create);
  static SignTransactionResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get signId => $_getSZ(0);
  @$pb.TagNumber(1)
  set signId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSignId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get txId => $_getSZ(1);
  @$pb.TagNumber(2)
  set txId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTxId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get rawTx => $_getSZ(2);
  @$pb.TagNumber(3)
  set rawTx($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRawTx() => $_has(2);
  @$pb.TagNumber(3)
  void clearRawTx() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
