//
//  Generated code. Do not modify.
//  source: keystone/chains/bch_transaction.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'btc_transaction.pb.dart' as $0;

class BchTx_Input extends $pb.GeneratedMessage {
  factory BchTx_Input({
    $core.String? hash,
    $core.int? index,
    $fixnum.Int64? value,
    $core.String? pubkey,
    $core.String? ownerKeyPath,
  }) {
    final $result = create();
    if (hash != null) {
      $result.hash = hash;
    }
    if (index != null) {
      $result.index = index;
    }
    if (value != null) {
      $result.value = value;
    }
    if (pubkey != null) {
      $result.pubkey = pubkey;
    }
    if (ownerKeyPath != null) {
      $result.ownerKeyPath = ownerKeyPath;
    }
    return $result;
  }
  BchTx_Input._() : super();
  factory BchTx_Input.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BchTx_Input.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BchTx.Input', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hash')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'index', $pb.PbFieldType.O3)
    ..aInt64(3, _omitFieldNames ? '' : 'value')
    ..aOS(4, _omitFieldNames ? '' : 'pubkey')
    ..aOS(5, _omitFieldNames ? '' : 'ownerKeyPath', protoName: 'ownerKeyPath')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BchTx_Input clone() => BchTx_Input()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BchTx_Input copyWith(void Function(BchTx_Input) updates) => super.copyWith((message) => updates(message as BchTx_Input)) as BchTx_Input;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BchTx_Input create() => BchTx_Input._();
  BchTx_Input createEmptyInstance() => create();
  static $pb.PbList<BchTx_Input> createRepeated() => $pb.PbList<BchTx_Input>();
  @$core.pragma('dart2js:noInline')
  static BchTx_Input getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BchTx_Input>(create);
  static BchTx_Input? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get value => $_getI64(2);
  @$pb.TagNumber(3)
  set value($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get pubkey => $_getSZ(3);
  @$pb.TagNumber(4)
  set pubkey($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPubkey() => $_has(3);
  @$pb.TagNumber(4)
  void clearPubkey() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get ownerKeyPath => $_getSZ(4);
  @$pb.TagNumber(5)
  set ownerKeyPath($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasOwnerKeyPath() => $_has(4);
  @$pb.TagNumber(5)
  void clearOwnerKeyPath() => clearField(5);
}

class BchTx extends $pb.GeneratedMessage {
  factory BchTx({
    $fixnum.Int64? fee,
    $core.int? dustThreshold,
    $core.String? memo,
    $core.Iterable<BchTx_Input>? inputs,
    $core.Iterable<$0.Output>? outputs,
  }) {
    final $result = create();
    if (fee != null) {
      $result.fee = fee;
    }
    if (dustThreshold != null) {
      $result.dustThreshold = dustThreshold;
    }
    if (memo != null) {
      $result.memo = memo;
    }
    if (inputs != null) {
      $result.inputs.addAll(inputs);
    }
    if (outputs != null) {
      $result.outputs.addAll(outputs);
    }
    return $result;
  }
  BchTx._() : super();
  factory BchTx.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BchTx.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BchTx', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'fee')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'dustThreshold', $pb.PbFieldType.O3, protoName: 'dustThreshold')
    ..aOS(3, _omitFieldNames ? '' : 'memo')
    ..pc<BchTx_Input>(4, _omitFieldNames ? '' : 'inputs', $pb.PbFieldType.PM, subBuilder: BchTx_Input.create)
    ..pc<$0.Output>(5, _omitFieldNames ? '' : 'outputs', $pb.PbFieldType.PM, subBuilder: $0.Output.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BchTx clone() => BchTx()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BchTx copyWith(void Function(BchTx) updates) => super.copyWith((message) => updates(message as BchTx)) as BchTx;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BchTx create() => BchTx._();
  BchTx createEmptyInstance() => create();
  static $pb.PbList<BchTx> createRepeated() => $pb.PbList<BchTx>();
  @$core.pragma('dart2js:noInline')
  static BchTx getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BchTx>(create);
  static BchTx? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get fee => $_getI64(0);
  @$pb.TagNumber(1)
  set fee($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFee() => $_has(0);
  @$pb.TagNumber(1)
  void clearFee() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get dustThreshold => $_getIZ(1);
  @$pb.TagNumber(2)
  set dustThreshold($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDustThreshold() => $_has(1);
  @$pb.TagNumber(2)
  void clearDustThreshold() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get memo => $_getSZ(2);
  @$pb.TagNumber(3)
  set memo($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMemo() => $_has(2);
  @$pb.TagNumber(3)
  void clearMemo() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<BchTx_Input> get inputs => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$0.Output> get outputs => $_getList(4);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
