//
//  Generated code. Do not modify.
//  source: keystone/base.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'payload.pb.dart' as $4;

enum Base_Content {
  hotVersion, 
  coldVersion, 
  notSet
}

class Base extends $pb.GeneratedMessage {
  factory Base({
    $core.int? version,
    $core.String? description,
    $4.Payload? payloadData,
    $core.int? hotVersion,
    $core.int? coldVersion,
    $core.String? deviceType,
  }) {
    final $result = create();
    if (version != null) {
      $result.version = version;
    }
    if (description != null) {
      $result.description = description;
    }
    if (payloadData != null) {
      $result.payloadData = payloadData;
    }
    if (hotVersion != null) {
      $result.hotVersion = hotVersion;
    }
    if (coldVersion != null) {
      $result.coldVersion = coldVersion;
    }
    if (deviceType != null) {
      $result.deviceType = deviceType;
    }
    return $result;
  }
  Base._() : super();
  factory Base.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Base.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Base_Content> _Base_ContentByTag = {
    4 : Base_Content.hotVersion,
    5 : Base_Content.coldVersion,
    0 : Base_Content.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Base', package: const $pb.PackageName(_omitMessageNames ? '' : 'protoc'), createEmptyInstance: create)
    ..oo(0, [4, 5])
    ..a<$core.int>(1, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOM<$4.Payload>(3, _omitFieldNames ? '' : 'payloadData', subBuilder: $4.Payload.create)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'hotVersion', $pb.PbFieldType.O3, protoName: 'hotVersion')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'coldVersion', $pb.PbFieldType.O3, protoName: 'coldVersion')
    ..aOS(6, _omitFieldNames ? '' : 'deviceType', protoName: 'deviceType')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Base clone() => Base()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Base copyWith(void Function(Base) updates) => super.copyWith((message) => updates(message as Base)) as Base;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Base create() => Base._();
  Base createEmptyInstance() => create();
  static $pb.PbList<Base> createRepeated() => $pb.PbList<Base>();
  @$core.pragma('dart2js:noInline')
  static Base getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Base>(create);
  static Base? _defaultInstance;

  Base_Content whichContent() => _Base_ContentByTag[$_whichOneof(0)]!;
  void clearContent() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.int get version => $_getIZ(0);
  @$pb.TagNumber(1)
  set version($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => clearField(2);

  @$pb.TagNumber(3)
  $4.Payload get payloadData => $_getN(2);
  @$pb.TagNumber(3)
  set payloadData($4.Payload v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasPayloadData() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayloadData() => clearField(3);
  @$pb.TagNumber(3)
  $4.Payload ensurePayloadData() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.int get hotVersion => $_getIZ(3);
  @$pb.TagNumber(4)
  set hotVersion($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasHotVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearHotVersion() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get coldVersion => $_getIZ(4);
  @$pb.TagNumber(5)
  set coldVersion($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasColdVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearColdVersion() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get deviceType => $_getSZ(5);
  @$pb.TagNumber(6)
  set deviceType($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDeviceType() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeviceType() => clearField(6);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
