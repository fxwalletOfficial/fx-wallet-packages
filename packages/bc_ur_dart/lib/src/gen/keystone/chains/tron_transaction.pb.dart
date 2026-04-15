//
//  Generated code. Do not modify.
//  source: keystone/chains/tron_transaction.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class LatestBlock extends $pb.GeneratedMessage {
  factory LatestBlock({
    $core.String? hash,
    $core.int? number,
    $fixnum.Int64? timestamp,
  }) {
    final $result = create();
    if (hash != null) {
      $result.hash = hash;
    }
    if (number != null) {
      $result.number = number;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    return $result;
  }
  LatestBlock._() : super();
  factory LatestBlock.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LatestBlock.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LatestBlock', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hash')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'number', $pb.PbFieldType.O3)
    ..aInt64(3, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LatestBlock clone() => LatestBlock()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LatestBlock copyWith(void Function(LatestBlock) updates) => super.copyWith((message) => updates(message as LatestBlock)) as LatestBlock;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LatestBlock create() => LatestBlock._();
  LatestBlock createEmptyInstance() => create();
  static $pb.PbList<LatestBlock> createRepeated() => $pb.PbList<LatestBlock>();
  @$core.pragma('dart2js:noInline')
  static LatestBlock getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LatestBlock>(create);
  static LatestBlock? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get number => $_getIZ(1);
  @$pb.TagNumber(2)
  set number($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearNumber() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => clearField(3);
}

class Override extends $pb.GeneratedMessage {
  factory Override({
    $core.String? tokenShortName,
    $core.String? tokenFullName,
    $core.int? decimals,
  }) {
    final $result = create();
    if (tokenShortName != null) {
      $result.tokenShortName = tokenShortName;
    }
    if (tokenFullName != null) {
      $result.tokenFullName = tokenFullName;
    }
    if (decimals != null) {
      $result.decimals = decimals;
    }
    return $result;
  }
  Override._() : super();
  factory Override.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Override.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Override', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tokenShortName', protoName: 'tokenShortName')
    ..aOS(2, _omitFieldNames ? '' : 'tokenFullName', protoName: 'tokenFullName')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'decimals', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Override clone() => Override()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Override copyWith(void Function(Override) updates) => super.copyWith((message) => updates(message as Override)) as Override;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Override create() => Override._();
  Override createEmptyInstance() => create();
  static $pb.PbList<Override> createRepeated() => $pb.PbList<Override>();
  @$core.pragma('dart2js:noInline')
  static Override getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Override>(create);
  static Override? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tokenShortName => $_getSZ(0);
  @$pb.TagNumber(1)
  set tokenShortName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTokenShortName() => $_has(0);
  @$pb.TagNumber(1)
  void clearTokenShortName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get tokenFullName => $_getSZ(1);
  @$pb.TagNumber(2)
  set tokenFullName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTokenFullName() => $_has(1);
  @$pb.TagNumber(2)
  void clearTokenFullName() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get decimals => $_getIZ(2);
  @$pb.TagNumber(3)
  set decimals($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDecimals() => $_has(2);
  @$pb.TagNumber(3)
  void clearDecimals() => clearField(3);
}

class TronTx extends $pb.GeneratedMessage {
  factory TronTx({
    $core.String? token,
    $core.String? contractAddress,
    $core.String? from,
    $core.String? to,
    $core.String? memo,
    $core.String? value,
    LatestBlock? latestBlock,
    Override? override,
    $core.int? fee,
  }) {
    final $result = create();
    if (token != null) {
      $result.token = token;
    }
    if (contractAddress != null) {
      $result.contractAddress = contractAddress;
    }
    if (from != null) {
      $result.from = from;
    }
    if (to != null) {
      $result.to = to;
    }
    if (memo != null) {
      $result.memo = memo;
    }
    if (value != null) {
      $result.value = value;
    }
    if (latestBlock != null) {
      $result.latestBlock = latestBlock;
    }
    if (override != null) {
      $result.override = override;
    }
    if (fee != null) {
      $result.fee = fee;
    }
    return $result;
  }
  TronTx._() : super();
  factory TronTx.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TronTx.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TronTx', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOS(2, _omitFieldNames ? '' : 'contractAddress', protoName: 'contractAddress')
    ..aOS(3, _omitFieldNames ? '' : 'from')
    ..aOS(4, _omitFieldNames ? '' : 'to')
    ..aOS(5, _omitFieldNames ? '' : 'memo')
    ..aOS(6, _omitFieldNames ? '' : 'value')
    ..aOM<LatestBlock>(7, _omitFieldNames ? '' : 'latestBlock', protoName: 'latestBlock', subBuilder: LatestBlock.create)
    ..aOM<Override>(8, _omitFieldNames ? '' : 'override', subBuilder: Override.create)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'fee', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TronTx clone() => TronTx()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TronTx copyWith(void Function(TronTx) updates) => super.copyWith((message) => updates(message as TronTx)) as TronTx;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TronTx create() => TronTx._();
  TronTx createEmptyInstance() => create();
  static $pb.PbList<TronTx> createRepeated() => $pb.PbList<TronTx>();
  @$core.pragma('dart2js:noInline')
  static TronTx getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TronTx>(create);
  static TronTx? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get contractAddress => $_getSZ(1);
  @$pb.TagNumber(2)
  set contractAddress($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContractAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearContractAddress() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get from => $_getSZ(2);
  @$pb.TagNumber(3)
  set from($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFrom() => $_has(2);
  @$pb.TagNumber(3)
  void clearFrom() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get to => $_getSZ(3);
  @$pb.TagNumber(4)
  set to($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTo() => $_has(3);
  @$pb.TagNumber(4)
  void clearTo() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get memo => $_getSZ(4);
  @$pb.TagNumber(5)
  set memo($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMemo() => $_has(4);
  @$pb.TagNumber(5)
  void clearMemo() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get value => $_getSZ(5);
  @$pb.TagNumber(6)
  set value($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearValue() => clearField(6);

  @$pb.TagNumber(7)
  LatestBlock get latestBlock => $_getN(6);
  @$pb.TagNumber(7)
  set latestBlock(LatestBlock v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasLatestBlock() => $_has(6);
  @$pb.TagNumber(7)
  void clearLatestBlock() => clearField(7);
  @$pb.TagNumber(7)
  LatestBlock ensureLatestBlock() => $_ensure(6);

  @$pb.TagNumber(8)
  Override get override => $_getN(7);
  @$pb.TagNumber(8)
  set override(Override v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasOverride() => $_has(7);
  @$pb.TagNumber(8)
  void clearOverride() => clearField(8);
  @$pb.TagNumber(8)
  Override ensureOverride() => $_ensure(7);

  @$pb.TagNumber(9)
  $core.int get fee => $_getIZ(8);
  @$pb.TagNumber(9)
  set fee($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasFee() => $_has(8);
  @$pb.TagNumber(9)
  void clearFee() => clearField(9);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
