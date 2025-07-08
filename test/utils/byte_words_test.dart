import 'dart:typed_data';

import 'package:bc_ur_dart/src/utils/byte_words.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  final words = 'yktsbbswwnwmfefrttsnonbgmtnnjyltvwtybwnebydawswtzcbdjnrsdawzdsksurdtnsrywzzemusffwottppersfdptencxfnmhvatdldroskcljshdbantctpadmadjksnfevymtfpwmftmhfpwtlpfejsylfhecwzonnbmhcybtgwwelpflgmfezeonledtgocsfzhycypf';
  final input = 'f5d714c6f1eb453bd1cda512969e7487e5d4139f1125eff0fd0b6dbf25f22678df299cbdf2fe93cc42a3d8afbf48a936203c90e6d289b8c52171580e9d1fb12e0173cd45e19641eb3a9041f0854571f73f35f2a5a0901a0d4fed85475245fea58a295518';

  test('Byte words encode', () {
    final result = ByteWords.encode(Uint8List.fromList(hex.decode(input)));
    expect(result, words);
  });

  test('Byte words decode', () {
    final result = ByteWords.decode(words);
    expect(hex.encode(result), input);
  });
}
