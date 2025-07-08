class URSeq {
  int length;
  int num;

  URSeq({required this.length, required this.num});

  bool get isFragment => length > 0 && num > 0;

  static URSeq decode(String value) {
    final components = value.split('-');
    if (components.length != 2) return URSeq(num: 0, length: 0);

    final num = int.parse(components[0]);
    final length = int.parse(components[1]);
    if (num <= 0 || length <= 0) return URSeq(num: 0, length: 0);

    return URSeq(num: num, length: length);
  }

  void copy(URSeq? target) {
    if (target == null) return;

    num = target.num;
    length = target.length;
  }

  @override
  bool operator ==(Object other) => other is URSeq && num == other.num && length == other.length;

  @override
  int get hashCode => num + length;

  @override
  String toString() => '$num-$length';
}
