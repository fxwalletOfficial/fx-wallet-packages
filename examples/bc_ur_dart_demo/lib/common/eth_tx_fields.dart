import 'dart:convert';

import 'package:flutter/material.dart';

import '../encode/type_config.dart';
import 'mock_data.dart';

/// ETH 交易构建器参数收集器
/// 统一处理 signData 和交易构造器字段的优先级逻辑

/// 从 mock 数据获取默认私钥
String? getTestPrivKey(String type) {
  final mockData = kMockByType[type];
  return mockData?['_testPrivKey'] as String?;
}

/// 收集 ETH 交易参数
/// [type] - UR 类型，如 'eth-sign-request'
/// [fields] - 表单字段配置
/// [controllers] - 文本控制器
/// [dropdownValues] - 下拉框值
/// [txBuilderParams] - 交易构建器参数
///
/// 返回合并后的参数字典，signData 和交易字段根据规则自动选择
Map<String, dynamic> collectEthTxParams({
  required String type,
  required List<FieldConfig> fields,
  required Map<String, TextEditingController> controllers,
  required Map<String, String> dropdownValues,
  required Map<String, dynamic> txBuilderParams,
}) {
  final params = <String, dynamic>{};

  for (final field in fields) {
    // 跳过 signData 字段，使用交易构造器参数
    if (field.key == 'signData' && txBuilderParams.isNotEmpty) {
      continue;
    }
    if (field.type == FieldType.dropdown) {
      params[field.key] = dropdownValues[field.key];
    } else if (field.type == FieldType.jsonList || field.type == FieldType.jsonMap) {
      final text = controllers[field.key]!.text.trim();
      if (text.isNotEmpty && text != '[]' && text != '{}') {
        try {
          params[field.key] = jsonDecode(text);
        } catch (_) {
          params[field.key] = text;
        }
      }
    } else {
      final val = controllers[field.key]!.text.trim();
      if (val.isNotEmpty) params[field.key] = val;
    }
  }

  // 添加交易构造器参数
  if (txBuilderParams.isNotEmpty) {
    params.addAll(txBuilderParams);
  }

  // 从 mock 数据获取默认私钥（用于 EIP-7702）
  final testPrivKey = getTestPrivKey(type);
  if (testPrivKey != null && testPrivKey.isNotEmpty && params['_testPrivKey'] == null) {
    params['_testPrivKey'] = testPrivKey;
  }

  return params;
}

/// ETH signData 字段的验证器
/// 当字段必填时，验证是否有 signData 或交易构造器参数
String? Function(String?)? ethSignDataValidator({
  required bool required,
  required Map<String, dynamic> txBuilderParams,
}) {
  if (!required) return null;
  return (v) {
    if ((v == null || v.trim().isEmpty) && txBuilderParams.isEmpty) {
      return 'Sign Data is required (enter hex or build transaction)';
    }
    return null;
  };
}

/// 填充 Mock 数据
/// 返回需要更新的 controllers 和 dropdownValues
/// 同时返回是否需要清空 txBuilderParams
void fillMockToEthTxControllers({
  required String type,
  required List<FieldConfig> fields,
  required Map<String, TextEditingController> controllers,
  required Map<String, String> dropdownValues,
  required void Function() clearTxBuilderParams,
}) {
  final mock = kMockByType[type] ?? {};
  
  // 清空交易构造器参数，恢复为 signData 模式
  clearTxBuilderParams();

  for (final field in fields) {
    final mockVal = mock[field.key];
    if (mockVal == null) continue;
    if (field.type == FieldType.dropdown) {
      dropdownValues[field.key] = mockVal.toString();
    } else if (field.type == FieldType.jsonList || field.type == FieldType.jsonMap) {
      controllers[field.key]?.text = const JsonEncoder.withIndent('  ').convert(mockVal);
    } else {
      controllers[field.key]?.text = mockVal.toString();
    }
  }
}
