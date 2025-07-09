import 'dart:typed_data';

import '../utils/constants/op.dart';
import '../utils/script.dart';

bool inputCheck(List<dynamic>? chunks) {
  return chunks != null && chunks.length == 2 && isCanonicalScriptSignature(chunks[0]) && isCanonicalPubKey(chunks[1]);
}

bool outputCheck(Uint8List script) {
  final buffer = compile(script)!;
  return buffer.length == 22 && buffer[0] == OPS['OP_0'] && buffer[1] == 0x14;
}
