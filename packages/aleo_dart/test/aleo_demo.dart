import 'package:aleo_dart/aleo.dart';

final position = 'test/rust_test.dll';
final dyLib = DyLib.getDyLibByPosition(position);
final rust = AleoAccount(dyLib);
void main() {
  final int a = 10;
  final int b = 32;
  print(rust.testRustFFi(a, b));
}
