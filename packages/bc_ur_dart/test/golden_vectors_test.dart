// BCR cross-implementation golden vectors.
//
// SOURCE: Blockchain Commons "Wolf" test vectors, published in
//   https://github.com/BlockchainCommons/bc-ur  (mirrored in bc-ur-rust, URKit).
// Verified: 2026-06-30; see docs/superpowers/plans/2026-06-30-ur-protocol-correctness.md
// for provenance details. These tests are hermetic: normal local/CI runs must
// not fetch the network.
// These expected values are copied from that upstream reference and MUST NOT be
// regenerated from bc_ur_dart. They verify protocol compatibility (BCR-2020-005,
// BCR-2020-012, BCR-2024-001), not internal round-trip consistency.

import 'dart:typed_data';

import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/byte_words.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  const payload50Hex = '5832916ec65cf77cadf55cd7f9cda1a1030026ddd42e905b77adc36e4f2d3ccba44f7f04f2de44f42d84c374a0e149136f25b018';
  const payload50Words = 'hdeymejtswhhylkepmykhhtsytsnoyoyaxaedsuttydmmhhpktpmsrjtgwdpfnsboxgwlbaawzuefywkdplrsrjynbvygabwjldapfcsdwkbrkch';
  const singlePartUR = 'UR:BYTES/HDEYMEJTSWHHYLKEPMYKHHTSYTSNOYOYAXAEDSUTTYDMMHHPKTPMSRJTGWDPFNSBOXGWLBAAWZUEFYWKDPLRSRJYNBVYGABWJLDAPFCSDWKBRKCH';

  const payload256Hex =
      '590100916ec65cf77cadf55cd7f9cda1a1030026ddd42e905b77adc36e4f2d3ccba44f7f04f2de44f42d84c374a0e149136f25b01852545961d55f7f7a8cde6d0e2ec43f3b2dcb644a2209e8c9e34af5c4747984a5e873c9cf5f965e25ee29039fdf8ca74f1c769fc07eb7ebaec46e0695aea6cbd60b3ec4bbff1b9ffe8a9e7240129377b9d3711ed38d412fbb4442256f1e6f595e0fc57fed451fb0a0101fb76b1fb1e1b88cfdfdaa946294a47de8fff173f021c0e6f65b05c0a494e50791270a0050a73ae69b6725505a2ec8a5791457c9876dd34aadd192a53aa0dc66b556c0c215c7ceb8248b717c22951e65305b56a3706e3e86eb01c803bbf915d80edcd64d4d';

  const expectedParts = <String>[
    'ur:bytes/1-9/lpadascfadaxcywenbpljkhdcahkadaemejtswhhylkepmykhhtsytsnoyoyaxaedsuttydmmhhpktpmsrjtdkgslpgh',
    'ur:bytes/2-9/lpaoascfadaxcywenbpljkhdcagwdpfnsboxgwlbaawzuefywkdplrsrjynbvygabwjldapfcsgmghhkhstlrdcxaefz',
    'ur:bytes/3-9/lpaxascfadaxcywenbpljkhdcahelbknlkuejnbadmssfhfrdpsbiegecpasvssovlgeykssjykklronvsjksopdzmol',
    'ur:bytes/4-9/lpaaascfadaxcywenbpljkhdcasotkhemthydawydtaxneurlkosgwcekonertkbrlwmplssjtammdplolsbrdzcrtas',
    'ur:bytes/5-9/lpahascfadaxcywenbpljkhdcatbbdfmssrkzmcwnezelennjpfzbgmuktrhtejscktelgfpdlrkfyfwdajldejokbwf',
    'ur:bytes/6-9/lpamascfadaxcywenbpljkhdcackjlhkhybssklbwefectpfnbbectrljectpavyrolkzczcpkmwidmwoxkilghdsowp',
    'ur:bytes/7-9/lpatascfadaxcywenbpljkhdcavszmwnjkwtclrtvaynhpahrtoxmwvwatmedibkaegdosftvandiodagdhthtrlnnhy',
    'ur:bytes/8-9/lpayascfadaxcywenbpljkhdcadmsponkkbbhgsoltjntegepmttmoonftnbuoiyrehfrtsabzsttorodklubbuyaetk',
    'ur:bytes/9-9/lpasascfadaxcywenbpljkhdcajskecpmdckihdyhphfotjojtfmlnwmadspaxrkytbztpbauotbgtgtaeaevtgavtny',
    'ur:bytes/10-9/lpbkascfadaxcywenbpljkhdcahkadaemejtswhhylkepmykhhtsytsnoyoyaxaedsuttydmmhhpktpmsrjtwdkiplzs',
    'ur:bytes/11-9/lpbdascfadaxcywenbpljkhdcahelbknlkuejnbadmssfhfrdpsbiegecpasvssovlgeykssjykklronvsjkvetiiapk',
    'ur:bytes/12-9/lpbnascfadaxcywenbpljkhdcarllaluzmdmgstospeyiefmwejlwtpedamktksrvlcygmzemovovllarodtmtbnptrs',
    'ur:bytes/13-9/lpbtascfadaxcywenbpljkhdcamtkgtpknghchchyketwsvwgwfdhpgmgtylctotzopdrpayoschcmhplffziachrfgd',
    'ur:bytes/14-9/lpbaascfadaxcywenbpljkhdcapazewnvonnvdnsbyleynwtnsjkjndeoldydkbkdslgjkbbkortbelomueekgvstegt',
    'ur:bytes/15-9/lpbsascfadaxcywenbpljkhdcaynmhpddpzmversbdqdfyrehnqzlugmjzmnmtwmrouohtstgsbsahpawkditkckynwt',
    'ur:bytes/16-9/lpbeascfadaxcywenbpljkhdcawygekobamwtlihsnpalnsghenskkiynthdzotsimtojetprsttmukirlrsbtamjtpd',
    'ur:bytes/17-9/lpbyascfadaxcywenbpljkhdcamklgftaxykpewyrtqzhydntpnytyisincxmhtbceaykolduortotiaiaiafhiaoyce',
    'ur:bytes/18-9/lpbgascfadaxcywenbpljkhdcahkadaemejtswhhylkepmykhhtsytsnoyoyaxaedsuttydmmhhpktpmsrjtntwkbkwy',
    'ur:bytes/19-9/lpbwascfadaxcywenbpljkhdcadekicpaajootjzpsdrbalpeywllbdsnbinaerkurspbncxgslgftvtsrjtksplcpeo',
    'ur:bytes/20-9/lpbbascfadaxcywenbpljkhdcayapmrleeleaxpasfrtrdkncffwjyjzgyetdmlewtkpktgllepfrltataztksmhkbot',
  ];

  test('GOLDEN Bytewords minimal encode matches upstream (BCR-2020-012)', () {
    final payload = Uint8List.fromList(hex.decode(payload50Hex));
    expect(ByteWords.encode(payload), payload50Words);
    expect(hex.encode(ByteWords.decode(payload50Words)), payload50Hex);
  });

  test('GOLDEN single-part UR encode matches upstream (BCR-2020-005)', () {
    final payload = Uint8List.fromList(hex.decode(payload50Hex));
    final code = UR(type: 'bytes', payload: payload).encode();
    expect(code, singlePartUR);

    final decoded = UR.decode(singlePartUR);
    expect(decoded.type, 'bytes');
    expect(hex.encode(decoded.payload), payload50Hex);
  });

  test('GOLDEN multipart fixed-rate parts match upstream (BCR-2024-001)', () {
    final payload = Uint8List.fromList(hex.decode(payload256Hex));
    final encoder = UR(type: 'bytes', payload: payload, maxLength: 30);

    for (var i = 0; i < 9; i++) {
      expect(
        encoder.next().toLowerCase(),
        expectedParts[i],
        reason: 'fixed-rate part ${i + 1} diverged from upstream vector',
      );
    }
  });

  test('GOLDEN multipart rateless parts match upstream (BCR-2024-001)', () {
    final payload = Uint8List.fromList(hex.decode(payload256Hex));
    final encoder = UR(type: 'bytes', payload: payload, maxLength: 30);

    for (var i = 0; i < 9; i++) {
      encoder.next();
    }
    for (var i = 9; i < expectedParts.length; i++) {
      expect(
        encoder.next().toLowerCase(),
        expectedParts[i],
        reason: 'rateless part ${i + 1} diverged from upstream vector',
      );
    }
  });

  test('GOLDEN decode of upstream multipart parts recovers exact payload', () {
    final decoder = UR(maxLength: 30);
    for (final part in expectedParts) {
      decoder.read(part);
      if (decoder.isComplete) break;
    }
    expect(decoder.isComplete, isTrue);
    expect(hex.encode(decoder.payload), payload256Hex);
  });
}
