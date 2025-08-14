// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CosmosNetworkInfo _$NetworkInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['bech32_hrp'],
  );
  return CosmosNetworkInfo(
    bech32Hrp: json['bech32_hrp'] as String,
  );
}

Map<String, dynamic> _$NetworkInfoToJson(CosmosNetworkInfo instance) =>
    <String, dynamic>{
      'bech32_hrp': instance.bech32Hrp,
    };
