//
//  Generated code. Do not modify.
//  source: keystone/transaction.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'chains/bch_transaction.pb.dart' as $1;

enum SignTransaction_Transaction {
  bchTx, 
  notSet
}

class SignTransaction extends $pb.GeneratedMessage {
  factory SignTransaction({
    $core.String? coinCode,
    $core.String? signId,
    $core.String? hdPath,
    $fixnum.Int64? timestamp,
    $core.int? decimal,
    $1.BchTx? bchTx,
  }) {
    final $result = create();
    if (coinCode != null) {
      $result.coinCode = coinCode;
    }
    if (signId != null) {
      $result.signId = signId;
    }
    if (hdPath != null) {
      $result.hdPath = hdPath;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (decimal != null) {
      $result.decimal = decimal;
    }
    if (bchTx != null) {
      $result.bchTx = bchTx;
    }
    return $result;
  }
  SignTransaction._() : super();
  factory SignTransaction.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SignTransaction.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SignTransaction_Transaction> _SignTransaction_TransactionByTag = {
    10 : SignTransaction_Transaction.bchTx,
    0 : SignTransaction_Transaction.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SignTransaction', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..oo(0, [10])
    ..aOS(1, _omitFieldNames ? '' : 'coinCode', protoName: 'coinCode')
    ..aOS(2, _omitFieldNames ? '' : 'signId', protoName: 'signId')
    ..aOS(3, _omitFieldNames ? '' : 'hdPath', protoName: 'hdPath')
    ..aInt64(4, _omitFieldNames ? '' : 'timestamp')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'decimal', $pb.PbFieldType.O3)
    ..aOM<$1.BchTx>(10, _omitFieldNames ? '' : 'bchTx', protoName: 'bchTx', subBuilder: $1.BchTx.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SignTransaction clone() => SignTransaction()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SignTransaction copyWith(void Function(SignTransaction) updates) => super.copyWith((message) => updates(message as SignTransaction)) as SignTransaction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignTransaction create() => SignTransaction._();
  SignTransaction createEmptyInstance() => create();
  static $pb.PbList<SignTransaction> createRepeated() => $pb.PbList<SignTransaction>();
  @$core.pragma('dart2js:noInline')
  static SignTransaction getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SignTransaction>(create);
  static SignTransaction? _defaultInstance;

  SignTransaction_Transaction whichTransaction() => _SignTransaction_TransactionByTag[$_whichOneof(0)]!;
  void clearTransaction() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get coinCode => $_getSZ(0);
  @$pb.TagNumber(1)
  set coinCode($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCoinCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCoinCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get signId => $_getSZ(1);
  @$pb.TagNumber(2)
  set signId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSignId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get hdPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set hdPath($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHdPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearHdPath() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get timestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set timestamp($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get decimal => $_getIZ(4);
  @$pb.TagNumber(5)
  set decimal($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDecimal() => $_has(4);
  @$pb.TagNumber(5)
  void clearDecimal() => clearField(5);

  @$pb.TagNumber(10)
  $1.BchTx get bchTx => $_getN(5);
  @$pb.TagNumber(10)
  set bchTx($1.BchTx v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasBchTx() => $_has(5);
  @$pb.TagNumber(10)
  void clearBchTx() => clearField(10);
  @$pb.TagNumber(10)
  $1.BchTx ensureBchTx() => $_ensure(5);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
