import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/common/fragment.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/byte_words.dart';
import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  test('Encode/Decode single part UR', () {
    final type = 'bytes';
    final payload =
        '5832916ec65cf77cadf55cd7f9cda1a1030026ddd42e905b77adc36e4f2d3ccba44f7f04f2de44f42d84c374a0e149136f25b018';
    final code =
        'ur:bytes/hdeymejtswhhylkepmykhhtsytsnoyoyaxaedsuttydmmhhpktpmsrjtgwdpfnsboxgwlbaawzuefywkdplrsrjynbvygabwjldapfcsdwkbrkch';
    final ur = UR.decode(code);

    expect(ur.type, type);
    expect(hex.encode(ur.payload), payload);
    expect(ur.encode(), code.toUpperCase());
  });

  test('Encode/Decode multi part UR', () {
    final payload =
        '590100916ec65cf77cadf55cd7f9cda1a1030026ddd42e905b77adc36e4f2d3ccba44f7f04f2de44f42d84c374a0e149136f25b01852545961d55f7f7a8cde6d0e2ec43f3b2dcb644a2209e8c9e34af5c4747984a5e873c9cf5f965e25ee29039fdf8ca74f1c769fc07eb7ebaec46e0695aea6cbd60b3ec4bbff1b9ffe8a9e7240129377b9d3711ed38d412fbb4442256f1e6f595e0fc57fed451fb0a0101fb76b1fb1e1b88cfdfdaa946294a47de8fff173f021c0e6f65b05c0a494e50791270a0050a73ae69b6725505a2ec8a5791457c9876dd34aadd192a53aa0dc66b556c0c215c7ceb8248b717c22951e65305b56a3706e3e86eb01c803bbf915d80edcd64d4d';
    final parts = [
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
      'ur:bytes/20-9/lpbbascfadaxcywenbpljkhdcayapmrleeleaxpasfrtrdkncffwjyjzgyetdmlewtkpktgllepfrltataztksmhkbot'
    ];

    final ur = UR(maxLength: 30);
    for (final part in parts) {
      ur.read(part);
      if (ur.isComplete) break;
    }

    expect(hex.encode(ur.payload), payload);
    for (final part in parts) {
      final item = ur.next();
      expect(item.toLowerCase(), part);
    }
  });

  test('UR type accepts digits per BCR syntax', () {
    final payload = Uint8List.fromList([1, 2, 3, 4]);
    final code = UR(type: 'crypto-psbt2', payload: payload).encode();
    final decoded = UR.decode(code);

    expect(decoded.type, 'crypto-psbt2');
    expect(hex.encode(decoded.payload), hex.encode(payload));
  });

  test('Read rejects corrupt single-part UR without throwing', () {
    final code = UR(type: 'bytes', payload: Uint8List.fromList([1, 2, 3, 4]))
        .encode()
        .toLowerCase();
    final corrupt = '${code.substring(0, code.length - 2)}aa';
    final ur = UR();

    expect(ur.read(corrupt), isFalse);
    expect(ur.isComplete, isFalse);
    expect(() => UR.decode(corrupt), throwsException);
  });

  test('Read rejects corrupt multipart reassembly and can recover', () {
    final payload =
        Uint8List.fromList(List.generate(128, (i) => (i * 17 + 3) & 0xff));
    final encoder = UR(type: 'bytes', payload: payload, maxLength: 30);
    final parts = List.generate(20, (_) => encoder.next().toLowerCase());
    final seqLength = FragmentUR.fromUR(ur: UR.decode(parts.first)).seq.length;
    final corruptParts = parts.map((part) {
      final fragment = FragmentUR.fromUR(ur: UR.decode(part));
      return FragmentUR(
        type: fragment.type,
        seq: fragment.seq,
        messageLength: fragment.messageLength,
        checksum: fragment.checksum ^ 1,
        part: fragment.part,
      ).encode();
    }).toList();

    final decoder = UR(maxLength: 30);
    for (final part in corruptParts.take(seqLength)) {
      decoder.read(part);
      if (decoder.isComplete) break;
    }
    expect(decoder.isComplete, isFalse);

    for (final part in parts) {
      decoder.read(part);
      if (decoder.isComplete) break;
    }
    expect(decoder.isComplete, isTrue);
    expect(hex.encode(decoder.payload), hex.encode(payload));
  });

  test('Out-of-order fragments recover the payload', () {
    final payload =
        '590100916ec65cf77cadf55cd7f9cda1a1030026ddd42e905b77adc36e4f2d3ccba44f7f04f2de44f42d84c374a0e149136f25b01852545961d55f7f7a8cde6d0e2ec43f3b2dcb644a2209e8c9e34af5c4747984a5e873c9cf5f965e25ee29039fdf8ca74f1c769fc07eb7ebaec46e0695aea6cbd60b3ec4bbff1b9ffe8a9e7240129377b9d3711ed38d412fbb4442256f1e6f595e0fc57fed451fb0a0101fb76b1fb1e1b88cfdfdaa946294a47de8fff173f021c0e6f65b05c0a494e50791270a0050a73ae69b6725505a2ec8a5791457c9876dd34aadd192a53aa0dc66b556c0c215c7ceb8248b717c22951e65305b56a3706e3e86eb01c803bbf915d80edcd64d4d';
    final parts = [
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
      'ur:bytes/20-9/lpbbascfadaxcywenbpljkhdcayapmrleeleaxpasfrtrdkncffwjyjzgyetdmlewtkpktgllepfrltataztksmhkbot'
    ];

    final ur = UR(maxLength: 30);
    for (final part in parts.reversed) {
      ur.read(part);
      if (ur.isComplete) break;
    }

    expect(ur.isComplete, isTrue);
    expect(hex.encode(ur.payload), payload);
  });

  test('Large payload round-trips through fragmentation', () {
    final payload =
        Uint8List.fromList(List.generate(4096, (i) => (i * 31 + 7) & 0xff));
    final encoder = UR(type: 'bytes', payload: payload, maxLength: 100);

    final decoder = UR();
    var guard = 0;
    while (!decoder.isComplete) {
      decoder.read(encoder.next());
      if (++guard > 10000) fail('Did not complete within fountain budget');
    }

    expect(decoder.isComplete, isTrue);
    expect(hex.encode(decoder.payload), hex.encode(payload));
  });

  test('read() rejects a fragment whose seqLength exceeds the safety cap', () {
    // A bytewords-valid, field-consistent frame whose seqLength is just above the
    // 0x10000 cap. Without the cap it is accepted into decode state and _check runs
    // List.generate(seqLength) — an unbounded allocation on the streaming path.
    const overCap = 0x10000 + 1;
    final crafted = Uint8List.fromList(cbor.encode(CborList([
      CborSmallInt(1),
      CborInt(BigInt.from(overCap)),
      CborInt(BigInt.from(overCap)),
      CborSmallInt(0),
      CborBytes([0]),
    ])));
    final frame =
        'ur:bytes/1-$overCap/${ByteWords.encode(crafted)}'.toLowerCase();

    final decoder = UR();
    expect(decoder.read(frame), isFalse);
    // Must be rejected before any decode state is locked in.
    expect(decoder.type, isEmpty);
    expect(decoder.expectedPartIndexes, isEmpty);
    expect(decoder.isComplete, isFalse);
  });

  test('read() does not let a single-part frame hijack a multipart decode', () {
    final multi = Uint8List.fromList(List.generate(120, (i) => (i * 3) & 0xff));
    final encoder = UR(type: 'bytes', payload: multi, maxLength: 40);

    final decoder = UR();
    decoder.read(encoder.next()); // start a multipart accumulation
    expect(decoder.isComplete, isFalse);

    // A valid, unrelated single-part UR must be skipped, not accepted.
    final stray = UR(type: 'bytes', payload: Uint8List.fromList([9, 9, 9, 9]));
    expect(decoder.read(stray.encode()), isFalse);
    expect(decoder.isComplete, isFalse);

    var guard = 0;
    while (!decoder.isComplete && guard < 5000) {
      decoder.read(encoder.next());
      guard++;
    }
    expect(decoder.isComplete, isTrue);
    expect(hex.encode(decoder.payload), hex.encode(multi));
  });

  test('reset() lets a reused decoder switch to a different message', () {
    final a = Uint8List.fromList(List.generate(120, (i) => (i * 3) & 0xff));
    final b = Uint8List.fromList(List.generate(120, (i) => (i * 7 + 1) & 0xff));
    final encA = UR(type: 'bytes', payload: a, maxLength: 40);
    final encB = UR(type: 'bytes', payload: b, maxLength: 40);

    final decoder = UR();
    decoder.read(encA.next()); // lock onto message A
    expect(decoder.isComplete, isFalse);

    // Without reset, B's fragments are rejected forever (different checksum).
    decoder.reset();

    var guard = 0;
    while (!decoder.isComplete && guard < 5000) {
      decoder.read(encB.next());
      guard++;
    }
    expect(decoder.isComplete, isTrue);
    expect(hex.encode(decoder.payload), hex.encode(b));
  });

  test('read() tolerates out-of-range fragment fields without crashing', () {
    // checksum = 2^32 (> uint32) would drive intToByte(checksum, 4) -> RangeError
    // (a Dart Error, not a URException) unless fromUR rejects it first.
    final hugeChecksum = Uint8List.fromList(cbor.encode(CborList([
      CborSmallInt(1),
      CborSmallInt(2),
      CborSmallInt(4),
      CborInt(BigInt.from(0x100000000)),
      CborBytes([0, 0, 0, 0]),
    ])));
    final frame =
        'ur:bytes/1-2/${ByteWords.encode(hugeChecksum)}'.toLowerCase();

    final decoder = UR();
    expect(decoder.read(frame), isFalse);
    expect(decoder.isComplete, isFalse);
  });
}
