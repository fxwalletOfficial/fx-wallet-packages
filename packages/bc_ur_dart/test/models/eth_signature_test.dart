import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  const String MASTER_FINGERPRINT = '4245356866';
  final path = "m/44'/60'/0'/0/0";
  final chainId = 1;
  final address = '0x68c6Fe222de676e9db081253fd808922047626eC';
  final uuid = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
  final origin = 'wallet';
  final tx = Eip1559TxData(
    data: EthTxDataRaw(
      nonce: 0,
      gasLimit: 21000,
      value: BigInt.zero,
      to: '0xa12AD11e6699344e20758915695bD5538420E318',
      maxPriorityFeePerGas: 1000000000,
      maxFeePerGas: 2000000000,
      data: '0x62015bdc000000000000000000000000414ca8715310264d8610057f55d0b6e0fa39a720'
    ),
    network: TxNetwork(chainId: chainId)
  );

  final code = 'UR:ETH-SIGNATURE/OEADTPDAGDAEADAOAXAAAHAMATAYASBKBDBNBTBABSAOHDFPAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEADAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAOVWUTKBWSRY';

  test('Eth signature encode', () {
    final request = EthSignRequestUR.fromTypedTransaction(tx: tx, address: address, path: path, uuid: uuid, origin: origin, xfp: MASTER_FINGERPRINT);
    final ur = EthSignatureUR.fromSignature(request: request, r: BigInt.one, s: BigInt.two, v: 0);
    expect(ur.encode(), code);
  });

  test('Eth signature decode', () {
    final request = EthSignRequestUR.fromTypedTransaction(tx: tx, address: address, path: path, uuid: uuid, origin: origin, xfp: MASTER_FINGERPRINT);
    final target = EthSignatureUR.fromSignature(request: request, r: BigInt.one, s: BigInt.two, v: 0);

    final ur = UR.decode(code);
    final sig = EthSignatureUR.fromUR(ur: ur);

    expect(hex.encode(sig.uuid), hex.encode(uuid));
    expect(hex.encode(sig.signature), hex.encode(target.signature));
  });
}
