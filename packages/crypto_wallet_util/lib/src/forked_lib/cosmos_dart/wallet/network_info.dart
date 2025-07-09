// ignore_for_file: implementation_imports
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'network_info.g.dart';

/// Contains the information of a generic Cosmos-based network.
@JsonSerializable(explicitToJson: true)
class NetworkInfo extends Equatable {
  /// Bech32 human readable part of the addresses related to this network
  @JsonKey(name: 'bech32_hrp', required: true)
  final String bech32Hrp;

  NetworkInfo({
    required this.bech32Hrp,
  });

  factory NetworkInfo.fromSingleHost({
    required String bech32Hrp,
    required String host,
  }) {
    return NetworkInfo(bech32Hrp: bech32Hrp);
  }

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    return _$NetworkInfoFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$NetworkInfoToJson(this);
  }

  @override
  List<Object> get props {
    return [bech32Hrp];
  }

  @override
  String toString() {
    return '{ '
        'bech32: $bech32Hrp'
        '}';
  }
}
