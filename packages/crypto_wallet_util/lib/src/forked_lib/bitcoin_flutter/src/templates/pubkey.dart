import 'dart:typed_data';

import '../utils/script.dart';

bool inputCheck(List<dynamic> chunks) {
  return chunks.length == 1 && isCanonicalScriptSignature(chunks[0]);
}

bool outputCheck(Uint8List script) {
  return false;
}
