import 'package:blockchain_utils/blockchain_utils.dart';

class BtcUtils {
  static BigInt toSatoshi(String dec) {
    BigRational decx = BigRational.parseDecimal(dec);
    decx = decx * BigRational(BigInt.from(10).pow(8));
    return decx.toBigInt();
  }
}
