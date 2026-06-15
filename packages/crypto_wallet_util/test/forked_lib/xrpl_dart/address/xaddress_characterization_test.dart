import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/src/xrpl/address/xrpl.dart';

/// Characterization tests for XRPL classic <-> X-address conversion.
///
/// 这条路径(XRPAddress.toXAddress / fromXAddress)运行时未被 crypto_wallet_util 调用，
/// 但 blockchain_utils 1.x→6.x 升级会改动它：
///   * fromXAddress 里 decodeXAddress 返回的 `.item1/.item2` (Tuple→record)
///   * fromPublicKeyBytes 里 `encodeKey` 的参数签名变化
/// golden 用 XRPL 官方 X-address 文档向量交叉验证，确保升级后字节不变。
void main() {
  // XRPL 官方文档向量：经典地址 rHb9... 对应的 X-address。
  const classic = 'rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh';
  const xMainnet = 'XVPcpSm47b1CZkf5AkKM9a84dQHe3m4sBhsrA4XtnBECTAc';
  const xMainnetTag12345 = 'XVPcpSm47b1CZkf5AkKM9a84dQHe3mTAxgxfLw2qYoe7Boa';

  group('XRPL X-address conversion (pins pre-upgrade behavior)', () {
    test('classic -> X-address (no tag)', () {
      expect(XRPAddress(classic).toXAddress(), xMainnet);
    });

    test('classic -> X-address (with destination tag)', () {
      expect(XRPAddress(classic).toXAddress(tag: 12345), xMainnetTag12345);
    });

    test('X-address -> classic (no tag)', () {
      final back = XRPAddress.fromXAddress(xMainnet);
      expect(back.address, classic);
      expect(back.tag, isNull);
    });

    test('X-address -> classic (with tag) preserves tag', () {
      final back = XRPAddress.fromXAddress(xMainnetTag12345);
      expect(back.address, classic);
      expect(back.tag, 12345);
    });
  });
}
