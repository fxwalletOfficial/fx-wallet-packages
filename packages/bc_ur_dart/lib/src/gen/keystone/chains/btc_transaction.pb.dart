//
//  Generated code. Do not modify.
//  source: keystone/chains/btc_transaction.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class Output extends $pb.GeneratedMessage {
  factory Output({
    $core.String? address,
    $fixnum.Int64? value,
    $core.bool? isChange,
    $core.String? changeAddressPath,
  }) {
    final $result = create();
    if (address != null) {
      $result.address = address;
    }
    if (value != null) {
      $result.value = value;
    }
    if (isChange != null) {
      $result.isChange = isChange;
    }
    if (changeAddressPath != null) {
      $result.changeAddressPath = changeAddressPath;
    }
    return $result;
  }
  Output._() : super();
  factory Output.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Output.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Output', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'address')
    ..aInt64(2, _omitFieldNames ? '' : 'value')
    ..aOB(3, _omitFieldNames ? '' : 'isChange', protoName: 'isChange')
    ..aOS(4, _omitFieldNames ? '' : 'changeAddressPath', protoName: 'changeAddressPath')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Output clone() => Output()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Output copyWith(void Function(Output) updates) => super.copyWith((message) => updates(message as Output)) as Output;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Output create() => Output._();
  Output createEmptyInstance() => create();
  static $pb.PbList<Output> createRepeated() => $pb.PbList<Output>();
  @$core.pragma('dart2js:noInline')
  static Output getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Output>(create);
  static Output? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get address => $_getSZ(0);
  @$pb.TagNumber(1)
  set address($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddress() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get value => $_getI64(1);
  @$pb.TagNumber(2)
  set value($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isChange => $_getBF(2);
  @$pb.TagNumber(3)
  set isChange($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIsChange() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsChange() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get changeAddressPath => $_getSZ(3);
  @$pb.TagNumber(4)
  set changeAddressPath($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasChangeAddressPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearChangeAddressPath() => clearField(4);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
