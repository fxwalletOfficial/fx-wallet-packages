final RegExp _urExp = RegExp(r'^ur:([a-z\-]+)(/(\d+-\d+)){0,1}/([a-z]+)$');

extension URType on String {
  bool get isUR => _urExp.hasMatch(toLowerCase());

  RegExpMatch? getURMatch() => _urExp.firstMatch(toLowerCase());
}
