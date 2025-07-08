import 'dart:typed_data';

import 'package:bc_ur_dart/src/utils/crc32.dart';
import 'package:convert/convert.dart';

final RegExp _urPartition = RegExp(r'([a-z]{2})');

const int BYTE_WORD_NUM = 256;
const int BYTE_WORD_LENGTH = 4;
const int DIM = 26;

const String BYTE_WORDS = 'ableacidalsoapexaquaarchatomauntawayaxisbackbaldbarnbeltbetabiasbluebodybragbrewbulbbuzzcalmcashcatschefcityclawcodecolacookcostcruxcurlcuspcyandarkdatadaysdelidicedietdoordowndrawdropdrumdulldutyeacheasyechoedgeepicevenexamexiteyesfactfairfernfigsfilmfishfizzflapflewfluxfoxyfreefrogfuelfundgalagamegeargemsgiftgirlglowgoodgraygrimgurugushgyrohalfhanghardhawkheathelphighhillholyhopehornhutsicedideaidleinchinkyintoirisironitemjadejazzjoinjoltjowljudojugsjumpjunkjurykeepkenokeptkeyskickkilnkingkitekiwiknoblamblavalazyleaflegsliarlimplionlistlogoloudloveluaulucklungmainmanymathmazememomenumeowmildmintmissmonknailnavyneednewsnextnoonnotenumbobeyoboeomitonyxopenovalowlspaidpartpeckplaypluspoempoolposepuffpumapurrquadquizraceramprealredorichroadrockroofrubyruinrunsrustsafesagascarsetssilkskewslotsoapsolosongstubsurfswantacotasktaxitenttiedtimetinytoiltombtoystriptunatwinuglyundouniturgeuservastveryvetovialvibeviewvisavoidvowswallwandwarmwaspwavewaxywebswhatwhenwhizwolfworkyankyawnyellyogayurtzapszerozestzinczonezoom';

enum ByteWordsStyle {
  STANDARD,
  URI,
  MINIMAL
}

class ByteWords {
  static Uint8List decode(String value) {
    final part = _urPartition.allMatches(value).map((e) => e.group(0)!);
    final words = <int>[];
    for (final item in part) {
      final x = item[0].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
      final y = item[1].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);

      final offset = y * DIM + x;
      final value = lookUpTable[offset];
      words.add(value);
    }

    return Uint8List.fromList(words.sublist(0, words.length - 4));
  }

  static String encode(Uint8List data) {
    final crc = CRC32.compute(data).toRadixString(16).padLeft(8, '0');
    final buf = data + hex.decode(crc);

    String msg = '';
    for (final item in buf) {
      final word = BYTE_WORDS.substring(item * BYTE_WORD_LENGTH, (item * BYTE_WORD_LENGTH) + BYTE_WORD_LENGTH);
      msg = msg + word[0] + word[BYTE_WORD_LENGTH - 1];
    }

    return msg;
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
