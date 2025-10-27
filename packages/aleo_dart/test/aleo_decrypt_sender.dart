import 'package:aleo_dart/aleo.dart';

Future<void> main() async {
  final dyLib = DyLib.getDyLibFromCargo();
  final rustRecordLib = AleoRecord(dyLib, 'mainnet');
  final view_key = '';

  final record =
      'record1qvqsq4ez4746zjhrjkcv8fc44eulxx5ks86plw0y43fmvghj0x2xfngzqyxx66trwfhkxun9v35hguerqqpqzq9lavl9qm5hs5mkm8wawzaq3q5kfjrka4muq343c7twj460f3j0pa42wtj4h73sernjw8dux64vh4syvrg43pg0j0ju3r7qx0d76w4qs5eyy7s';
  final senderCiphertext =
      '6349782547135603480776001536343162867510891943969643243943353667889292513960field';

  final result =
      rustRecordLib.decryptSenderCiphertext(record, view_key, senderCiphertext);

  print(result);
}
