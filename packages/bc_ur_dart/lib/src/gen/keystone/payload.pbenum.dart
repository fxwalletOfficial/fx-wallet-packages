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

class Payload_Type extends $pb.ProtobufEnum {
  static const Payload_Type TYPE_RESERVE = Payload_Type._(0, _omitEnumNames ? '' : 'TYPE_RESERVE');
  static const Payload_Type TYPE_SIGN_TX = Payload_Type._(2, _omitEnumNames ? '' : 'TYPE_SIGN_TX');
  static const Payload_Type TYPE_SIGN_TX_RESULT = Payload_Type._(9, _omitEnumNames ? '' : 'TYPE_SIGN_TX_RESULT');

  static const $core.List<Payload_Type> values = <Payload_Type> [
    TYPE_RESERVE,
    TYPE_SIGN_TX,
    TYPE_SIGN_TX_RESULT,
  ];

  static final $core.Map<$core.int, Payload_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Payload_Type? valueOf($core.int value) => _byValue[value];

  const Payload_Type._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
