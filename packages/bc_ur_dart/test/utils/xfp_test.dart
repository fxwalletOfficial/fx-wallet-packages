import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  test('Get xfp - reverse bytes', () {
    final origin = 44262555;
    final result = getXfp(BigInt.from(origin), reverseBytes: true);
    expect(result, '9b64a302');
  });

  test('Get xfp - unreverse bytes', () {
    final xfp = getXfp(BigInt.from(4245356866), reverseBytes: false);
    expect(xfp, 'fd0b0142');
  });

  test('Byte words decode - reverse bytes', () {
    final result = toXfpCode('9b64a302', reverseBytes: true);
    expect(result, BigInt.from(44262555));
  });

  test('Byte words decode - unreverse bytes', () {
    final result = toXfpCode('fd0b0142', reverseBytes: false);
    expect(result, BigInt.from(4245356866));
  });
}
