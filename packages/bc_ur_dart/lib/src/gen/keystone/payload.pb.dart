//
//  Generated code. Do not modify.
//  source: keystone/payload.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'payload.pbenum.dart';
import 'sign_transaction_result.pb.dart' as $3;
import 'transaction.pb.dart' as $2;

export 'payload.pbenum.dart';

enum Payload_Content {
  signTx, 
  signTxResult, 
  notSet
}

class Payload extends $pb.GeneratedMessage {
  factory Payload({
    Payload_Type? type,
    $core.String? xfp,
    $2.SignTransaction? signTx,
    $3.SignTransactionResult? signTxResult,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (xfp != null) {
      $result.xfp = xfp;
    }
    if (signTx != null) {
      $result.signTx = signTx;
    }
    if (signTxResult != null) {
      $result.signTxResult = signTxResult;
    }
    return $result;
  }
  Payload._() : super();
  factory Payload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Payload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Payload_Content> _Payload_ContentByTag = {
    4 : Payload_Content.signTx,
    7 : Payload_Content.signTxResult,
    0 : Payload_Content.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Payload', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..oo(0, [4, 7])
    ..e<Payload_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: Payload_Type.TYPE_RESERVE, valueOf: Payload_Type.valueOf, enumValues: Payload_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'xfp')
    ..aOM<$2.SignTransaction>(4, _omitFieldNames ? '' : 'signTx', protoName: 'signTx', subBuilder: $2.SignTransaction.create)
    ..aOM<$3.SignTransactionResult>(7, _omitFieldNames ? '' : 'signTxResult', protoName: 'signTxResult', subBuilder: $3.SignTransactionResult.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Payload clone() => Payload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Payload copyWith(void Function(Payload) updates) => super.copyWith((message) => updates(message as Payload)) as Payload;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Payload create() => Payload._();
  Payload createEmptyInstance() => create();
  static $pb.PbList<Payload> createRepeated() => $pb.PbList<Payload>();
  @$core.pragma('dart2js:noInline')
  static Payload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Payload>(create);
  static Payload? _defaultInstance;

  Payload_Content whichContent() => _Payload_ContentByTag[$_whichOneof(0)]!;
  void clearContent() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Payload_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(Payload_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get xfp => $_getSZ(1);
  @$pb.TagNumber(2)
  set xfp($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasXfp() => $_has(1);
  @$pb.TagNumber(2)
  void clearXfp() => clearField(2);

  @$pb.TagNumber(4)
  $2.SignTransaction get signTx => $_getN(2);
  @$pb.TagNumber(4)
  set signTx($2.SignTransaction v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasSignTx() => $_has(2);
  @$pb.TagNumber(4)
  void clearSignTx() => clearField(4);
  @$pb.TagNumber(4)
  $2.SignTransaction ensureSignTx() => $_ensure(2);

  @$pb.TagNumber(7)
  $3.SignTransactionResult get signTxResult => $_getN(3);
  @$pb.TagNumber(7)
  set signTxResult($3.SignTransactionResult v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasSignTxResult() => $_has(3);
  @$pb.TagNumber(7)
  void clearSignTxResult() => clearField(7);
  @$pb.TagNumber(7)
  $3.SignTransactionResult ensureSignTxResult() => $_ensure(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
