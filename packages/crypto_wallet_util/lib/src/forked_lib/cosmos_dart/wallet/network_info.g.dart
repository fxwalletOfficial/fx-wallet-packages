// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkInfo _$NetworkInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['bech32_hrp'],
  );
  return NetworkInfo(
    bech32Hrp: json['bech32_hrp'] as String,
  );
}

Map<String, dynamic> _$NetworkInfoToJson(NetworkInfo instance) =>
    <String, dynamic>{
      'bech32_hrp': instance.bech32Hrp,
    };
