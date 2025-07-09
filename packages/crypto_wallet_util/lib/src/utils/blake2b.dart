import 'package:pointycastle/digests/blake2b.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Class for getting blake2b hex.
class Blake2b {
  static Uint8List getBlake2bHash(Uint8List input,
      {int size = 32, String personalization = ''}) {
    late final Blake2bDigest state;
    if (personalization == '') {
      state = Blake2bDigest(digestSize: size);
    } else {
      final bytes = utf8.encode(personalization);
      if (bytes.length != 16)
        throw Exception('personalization length must be exactly 16 bytes');
      state = Blake2bDigest(digestSize: size, personalization: bytes);
    }
    state.update(input, 0, input.length);
    var hash = Uint8List(32);
    state.doFinal(hash, 0);
    return hash.sublist(0, size);
  }

  late Blake2bDigest blake2bDigest;
  Blake2b({int digestSize = 32, String personalization = ''}) {
    if (personalization == '') {
      blake2bDigest = Blake2bDigest(digestSize: digestSize);
    } else {
      final bytes = utf8.encode(personalization);
      if (bytes.length != 16)
        throw Exception('personalization length must be exactly 16 bytes');
      blake2bDigest =
          Blake2bDigest(digestSize: digestSize, personalization: bytes);
    }
  }

  defaultUpdate(Uint8List hash) {
    blake2bDigest.update(hash, 0, hash.length);
  }

  update(Uint8List hash, int offset, int length) {
    blake2bDigest.update(hash, offset, length);
  }

  doFinal() {
    final array = Uint8List(blake2bDigest.digestSize);
    blake2bDigest.doFinal(array, 0);
    return array.sublist(0, 32);
  }
}
