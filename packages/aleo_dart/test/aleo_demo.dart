import 'package:aleo_dart/aleo.dart';

final dyLib = DyLib.getLocalDyLib();
final rust = AleoAccount(dyLib);
void main() {
  final mnemonic =
      "fly lecture gasp juice hover ice business census bless weapon polar upgrade";
  final result = rust.mnemonicToAddress(mnemonic);
  print(result);
}
