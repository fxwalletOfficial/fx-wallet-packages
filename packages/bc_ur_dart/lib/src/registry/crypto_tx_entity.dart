import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';

enum TxEntityKeys {
  zero, // 0 
  address, // 1
  amount, // 2
}

class CryptoTxEntity extends RegistryItem {
  final String? address;
  final Uint8List? amount;

  CryptoTxEntity({
    this.address,
    this.amount,
  });

  @override
  RegistryType getRegistryType() => RegistryType.CRYPTO_TXENTITY;

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};

    if (address != null) {
      map[CborSmallInt(TxEntityKeys.address.index)] = CborString(address!);
    }
    if (amount != null) {
      map[CborSmallInt(TxEntityKeys.amount.index)] = CborBytes(amount!);
    }

    return CborMap(map, tags: [getRegistryType().tag]);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    return CryptoTxEntity(
      address: RegistryItem.readOptionalText(map, TxEntityKeys.address.index),
      amount: RegistryItem.readOptionalBytes(map, TxEntityKeys.amount.index),
    );
  }

  static CryptoTxEntity fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<CryptoTxEntity>(
      cborPayload,
      CryptoTxEntity(),
    );
  }
}

/// 从 Map 构建 CryptoTxEntity
/// 用于业务层（如解析交易输出）
CryptoTxEntity parseTxEntity(Map<String, dynamic> txEntityMap) {
  final String? address = txEntityMap['address'] as String?;
  final Uint8List? amount = txEntityMap['amount'] != null ? bigIntToBytes(txEntityMap['amount']) : null;

  return CryptoTxEntity(
    address: address,
    amount: amount,
  );
}

/// CryptoTxEntity → Map，对应热钱包构造时的 parseTxEntity() 逆操作
List<Map<String, dynamic>> parseOutputs(List<CryptoTxEntity>? outputs) {
  if (outputs == null || outputs.isEmpty) return [];
  return outputs
      .map((e) => {
            'address': e.address, // CryptoTxEntity 字段，按实际定义调整
            'amount': e.amount,
          })
      .toList();
}
