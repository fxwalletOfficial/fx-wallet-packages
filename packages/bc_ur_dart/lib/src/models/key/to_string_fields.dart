import 'dart:convert';

/// 用于构建紧凑的调试字符串，自动跳过空字段。
class CompactToStringFields {
  final List<String> _fields = [];

  /// 添加字符串字段；[value] 为空时不输出。
  ///
  /// 值会经过 JSON 转义，确保包含引号、反斜杠或控制字符时输出仍是合法 JSON。
  void addString(String key, String? value) {
    if (value == null || value.isEmpty) return;
    _fields.add('${jsonEncode(key)}:${jsonEncode(value)}');
  }

  /// 添加已经格式化好的字段；[value] 为空时不输出。
  void addRaw(String key, String? value) {
    if (value == null || value.isEmpty) return;
    _fields.add('"$key":$value');
  }

  /// 添加原样字符串字段：用引号包裹但不做 JSON 转义；[value] 为空时不输出。
  ///
  /// 用于 note 等自由文本，保持与历史输出一致（不会把内部的引号/反斜杠转义）。
  void addRawString(String key, String? value) {
    if (value == null || value.isEmpty) return;
    _fields.add('"$key":"$value"');
  }

  @override
  String toString() => '{\n${_fields.join(',\n')}\n}';
}
