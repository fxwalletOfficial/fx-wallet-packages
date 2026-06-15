import 'dart:convert';

/// 用于构建 JSON-shaped 调试字符串。
class CompactToStringFields {
  final List<String> _fields = [];

  /// 添加字符串字段。
  ///
  /// 值会经过 JSON 转义，确保包含引号、反斜杠或控制字符时输出仍是合法 JSON。
  void addString(String key, String? value, {bool keepEmpty = true}) {
    if (value == null) {
      if (!keepEmpty) return;
      value = '';
    }
    if (value.isEmpty && !keepEmpty) return;
    _fields.add('${jsonEncode(key)}:${jsonEncode(value)}');
  }

  /// 添加已经格式化好的字段。
  void addRaw(String key, String? value, {bool keepNull = true}) {
    if (value == null || value.isEmpty) {
      if (!keepNull) return;
      value = 'null';
    }
    _fields.add('"$key":$value');
  }

  @override
  String toString() => '{\n${_fields.join(',\n')}\n}';
}
