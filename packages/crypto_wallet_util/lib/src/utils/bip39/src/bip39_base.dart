
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:crypto_wallet_util/src/utils/bip39/src/words/english.dart';
import 'package:hex/hex.dart';

import 'utils/pbkdf2.dart';

const int _SIZE_BYTE = 255;
const String _INVALID_MNEMONIC = 'Invalid mnemonic';
const String _INVALID_ENTROPY = 'Invalid entropy';
const String _INVALID_CHECKSUM = 'Invalid mnemonic checksum';

class BIP39 {
  static int _binaryToByte(String binary) {
    return int.parse(binary, radix: 2);
  }

  static String _bytesToBinary(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
  }

  static String _deriveChecksumBits(Uint8List entropy) {
    final ENT = entropy.length * 8;
    final CS = ENT ~/ 32;
    final hash = sha256.convert(entropy);
    return _bytesToBinary(Uint8List.fromList(hash.bytes)).substring(0, CS);
  }

  static Uint8List _randomBytes(int size) {
    final rng = Random.secure();
    final bytes = Uint8List(size);
    for (int i = 0; i < size; i++) {
      bytes[i] = rng.nextInt(_SIZE_BYTE);
    }
    return bytes;
  }

  static String generateMnemonic({int strength = 128}) {
    assert(strength % 32 == 0);
    final entropy = _randomBytes(strength ~/ 8);
    return entropyToMnemonic(HEX.encode(entropy));
  }

  static String entropyToMnemonic(String entropyString) {
    final entropy = Uint8List.fromList(HEX.decode(entropyString));

    if (entropy.length < 16) throw ArgumentError(_INVALID_ENTROPY);
    if (entropy.length > 32) throw ArgumentError(_INVALID_ENTROPY);
    if (entropy.length % 4 != 0) throw ArgumentError(_INVALID_ENTROPY);

    final entropyBits = _bytesToBinary(entropy);
    final checksumBits = _deriveChecksumBits(entropy);
    final bits = entropyBits + checksumBits;
    final regex = RegExp(r'.{1,11}', caseSensitive: false, multiLine: false);
    final chunks = regex
        .allMatches(bits)
        .map((match) => match.group(0)!)
        .toList(growable: false);
    List<String> wordlist = ENGLISH_WORDS;
    String words = chunks.map((binary) => wordlist[_binaryToByte(binary)]).join(' ');
    return words;
  }

  static Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    final pbkdf2 = PBKDF2();
    return pbkdf2.process(mnemonic, passphrase: passphrase);
  }

  static String mnemonicToSeedHex(String mnemonic, {String passphrase = ''}) {
    return mnemonicToSeed(mnemonic, passphrase: passphrase).map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join('');
  }

  static bool validateMnemonic(String mnemonic) {
    try {
      mnemonicToEntropy(mnemonic);
      return true;
    } catch (e) {
      return false;
    }
  }

  static String mnemonicToEntropy(String mnemonic) {
    var words = mnemonic.split(' ');
    if (words.length % 3 != 0) throw ArgumentError(_INVALID_MNEMONIC);

    final wordlist = ENGLISH_WORDS;
    // convert word indices to 11 bit binary strings
    final bits = words.map((word) {
      final index = wordlist.indexOf(word);
      if (index == -1) throw ArgumentError(_INVALID_MNEMONIC);

      return index.toRadixString(2).padLeft(11, '0');
    }).join('');
    // split the binary string into ENT/CS
    final dividerIndex = (bits.length / 33).floor() * 32;
    final entropyBits = bits.substring(0, dividerIndex);
    final checksumBits = bits.substring(dividerIndex);

    // calculate the checksum and compare
    final regex = RegExp(r'.{1,8}');
    final entropyBytes = Uint8List.fromList(regex
        .allMatches(entropyBits)
        .map((match) => _binaryToByte(match.group(0)!))
        .toList(growable: false));

    if (entropyBytes.length < 16) throw StateError(_INVALID_ENTROPY);
    if (entropyBytes.length > 32) throw StateError(_INVALID_ENTROPY);
    if (entropyBytes.length % 4 != 0) throw StateError(_INVALID_ENTROPY);

    final newChecksum = _deriveChecksumBits(entropyBytes);
    if (newChecksum != checksumBits) throw StateError(_INVALID_CHECKSUM);

    return entropyBytes.map((byte) {
      return byte.toRadixString(16).padLeft(2, '0');
    }).join('');
  }
}
