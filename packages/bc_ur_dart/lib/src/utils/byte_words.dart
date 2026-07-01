import 'dart:typed_data';

import 'package:bc_ur_dart/src/utils/crc32.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:convert/convert.dart';

final RegExp _minimalByteWords = RegExp(r'^[a-z]+$');

const int BYTE_WORD_NUM = 256;
const int BYTE_WORD_LENGTH = 4;
const int DIM = 26;

const String BYTE_WORDS =
    'ableacidalsoapexaquaarchatomauntawayaxisbackbaldbarnbeltbetabiasbluebodybragbrewbulbbuzzcalmcashcatschefcityclawcodecolacookcostcruxcurlcuspcyandarkdatadaysdelidicedietdoordowndrawdropdrumdulldutyeacheasyechoedgeepicevenexamexiteyesfactfairfernfigsfilmfishfizzflapflewfluxfoxyfreefrogfuelfundgalagamegeargemsgiftgirlglowgoodgraygrimgurugushgyrohalfhanghardhawkheathelphighhillholyhopehornhutsicedideaidleinchinkyintoirisironitemjadejazzjoinjoltjowljudojugsjumpjunkjurykeepkenokeptkeyskickkilnkingkitekiwiknoblamblavalazyleaflegsliarlimplionlistlogoloudloveluaulucklungmainmanymathmazememomenumeowmildmintmissmonknailnavyneednewsnextnoonnotenumbobeyoboeomitonyxopenovalowlspaidpartpeckplaypluspoempoolposepuffpumapurrquadquizraceramprealredorichroadrockroofrubyruinrunsrustsafesagascarsetssilkskewslotsoapsolosongstubsurfswantacotasktaxitenttiedtimetinytoiltombtoystriptunatwinuglyundouniturgeuservastveryvetovialvibeviewvisavoidvowswallwandwarmwaspwavewaxywebswhatwhenwhizwolfworkyankyawnyellyogayurtzapszerozestzinczonezoom';

enum ByteWordsStyle { STANDARD, URI, MINIMAL }

class ByteWords {
  static Uint8List decode(String value) {
    final normalized = value.toLowerCase();
    if (normalized.length < 8 || normalized.length.isOdd || !_minimalByteWords.hasMatch(normalized)) {
      throw InvalidFormatURException(input: value);
    }

    final words = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      final item = normalized.substring(i, i + 2);
      final x = item[0].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
      final y = item[1].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);

      final offset = y * DIM + x;
      final byte = lookUpTable[offset];
      if (byte < 0) throw InvalidFormatURException(input: value);
      words.add(byte);
    }

    final payload = Uint8List.fromList(words.sublist(0, words.length - 4));
    final expected = int.parse(hex.encode(words.sublist(words.length - 4)), radix: 16);
    final actual = CRC32.compute(payload);
    if (actual != expected) {
      throw InvalidChecksumURException(value: value);
    }

    return payload;
  }

  static String encode(Uint8List data) {
    final crc = CRC32.compute(data).toRadixString(16).padLeft(8, '0');
    final buf = data + hex.decode(crc);

    final msg = StringBuffer();
    for (final item in buf) {
      final word = BYTE_WORDS.substring(item * BYTE_WORD_LENGTH, (item * BYTE_WORD_LENGTH) + BYTE_WORD_LENGTH);
      msg.write(word[0]);
      msg.write(word[BYTE_WORD_LENGTH - 1]);
    }

    return msg.toString();
  }

  static List<int> _lookUpTable = [];
  static List<int> get lookUpTable {
    if (_lookUpTable.isNotEmpty) return _lookUpTable;

    final len = DIM * DIM;
    _lookUpTable = List.filled(len, -1);

    for (var i = 0; i < BYTE_WORD_NUM; i++) {
      final byteWord = BYTE_WORDS.substring(i * BYTE_WORD_LENGTH, (i * BYTE_WORD_LENGTH) + BYTE_WORD_LENGTH);
      final x = byteWord[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
      final y = byteWord[3].codeUnitAt(0) - 'a'.codeUnitAt(0);
      final offset = y * DIM + x;
      _lookUpTable[offset] = i;
    }

    return _lookUpTable;
  }
}
