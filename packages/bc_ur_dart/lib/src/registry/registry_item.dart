import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

abstract class RegistryItem {
  RegistryType getRegistryType();
  CborValue? toCborValue();
  
  Uint8List toCBOR() {
    final cborValue = toCborValue();
    if (cborValue == null) {
      throw "#[ur-registry][RegistryItem][fn.toCBOR]: "
            "registry ${getRegistryType()}'s method toCborValue returns undefined";
    }
    return Uint8List.fromList(cbor.encode(cborValue));
  }
  
  UR toUR() {
    return UR(
      type: getRegistryType().type,
      payload: toCBOR(),
      // 可以传递其他参数
      // minLength: 10,
      // maxLength: 200,
    );
  }
}
