///
//  Generated code. Do not modify.
//  source: cosmos/crypto/secp256k1/keys.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CosmosPubKey extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PubKey', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'cosmos.crypto.secp256k1'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'key', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  CosmosPubKey._() : super();
  factory CosmosPubKey({
    $core.List<$core.int>? key,
  }) {
    final result = create();
    if (key != null) result.key = key;

    return result;
  }
  factory CosmosPubKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CosmosPubKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CosmosPubKey clone() => CosmosPubKey()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CosmosPubKey copyWith(void Function(CosmosPubKey) updates) => super.copyWith((message) => updates(message as CosmosPubKey)) as CosmosPubKey; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CosmosPubKey create() => CosmosPubKey._();
  CosmosPubKey createEmptyInstance() => create();
  static $pb.PbList<CosmosPubKey> createRepeated() => $pb.PbList<CosmosPubKey>();
  @$core.pragma('dart2js:noInline')
  static CosmosPubKey getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CosmosPubKey>(create);
  static CosmosPubKey? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get key => $_getN(0);
  @$pb.TagNumber(1)
  set key($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
}

class CosmosPrivKey extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'PrivKey', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'cosmos.crypto.secp256k1'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'key', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  CosmosPrivKey._() : super();
  factory CosmosPrivKey({
    $core.List<$core.int>? key,
  }) {
    final result = create();
    if (key != null) result.key = key;

    return result;
  }
  factory CosmosPrivKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CosmosPrivKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CosmosPrivKey clone() => CosmosPrivKey()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CosmosPrivKey copyWith(void Function(CosmosPrivKey) updates) => super.copyWith((message) => updates(message as CosmosPrivKey)) as CosmosPrivKey; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CosmosPrivKey create() => CosmosPrivKey._();
  CosmosPrivKey createEmptyInstance() => create();
  static $pb.PbList<CosmosPrivKey> createRepeated() => $pb.PbList<CosmosPrivKey>();
  @$core.pragma('dart2js:noInline')
  static CosmosPrivKey getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CosmosPrivKey>(create);
  static CosmosPrivKey? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get key => $_getN(0);
  @$pb.TagNumber(1)
  set key($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
}

