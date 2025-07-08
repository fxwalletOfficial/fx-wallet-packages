import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  test('Get xfp - Big endian', () {
    final origin = 44262555;
    final result = getXfp(BigInt.from(origin));
    expect(result, '9b64a302');
  });

  test('Get xfp - Little endian', () {
    final xfp = getXfp(BigInt.from(4245356866), bigEndian: false);
    expect(xfp, 'fd0b0142');
  });

  test('Byte words decode', () {
    final result = toXfpCode('9b64a302');
    expect(result, BigInt.from(44262555));
  });

  test('Byte words decode - Little endian', () {
    final result = toXfpCode('fd0b0142', bigEndian: false);
    expect(result, BigInt.from(4245356866));
  });
}
