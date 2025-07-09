import 'dart:typed_data';

convertBit(Uint8List buff) {
  String str = '';
  for (var i = 0; i < buff.length; i++) {
    String res = buff[i].toRadixString(2);
    res = res.length < 8
      ? '00000000'.substring(0, 8 - res.length) + res
      : buff[i].toRadixString(2);

    str = str + res;
  }
  int len = (str.length / 5).ceil();
  List<int> arr = [];
  for (var i = 0; i < len; i++) {
    var info = str.substring(0, 5);
    str = str.substring(5);
    arr.add(int.parse(info, radix: 2));
  }
  arr.insert(0, 0);
  return arr;
}
