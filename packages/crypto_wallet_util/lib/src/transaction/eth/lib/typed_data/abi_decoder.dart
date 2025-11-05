import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/utils.dart';

/// ABI decoder for Ethereum smart contract function calls
class AbiDecoder {
  final Map<String, String> _functions = {};
  final Map<String, String> _signatures = {};
  final Map<String, List<dynamic>> _functionInputs = {};

  /// Create ABI decoder from contract ABI JSON
  AbiDecoder.fromABI(List<dynamic> abiJson) {
    for (final func in abiJson.where((e) => e['type'] == 'function')) {
      final signature =
          '${func['name']}(${_buildFunctionSignature(func['inputs'] as List)})';
      final selector = _calculateSelector(signature);
      _functions[selector] = func['name'] as String;
      _signatures[selector] = signature;
      _functionInputs[selector] = func['inputs'] as List<dynamic>;
    }
  }

  /// Build function signature string from inputs
  String _buildFunctionSignature(List<dynamic> inputs) {
    return inputs.map((input) => _getTypeSignature(input)).join(',');
  }

  /// Get type signature for ABI type, handling tuple expansion
  String _getTypeSignature(dynamic input) {
    final type = input['type'] as String;
    if (type == 'tuple') {
      final components = input['components'] as List;
      final componentTypes =
          components.map((comp) => _getTypeSignature(comp)).join(',');
      return '($componentTypes)';
    } else if (type == 'tuple[]') {
      final components = input['components'] as List;
      final componentTypes =
          components.map((comp) => _getTypeSignature(comp)).join(',');
      return '($componentTypes)[]';
    } else {
      return type;
    }
  }

  /// Calculate function selector using Keccak256
  String _calculateSelector(String signature) {
    final hash = getKeccakDigest(Uint8List.fromList(signature.codeUnits));
    return '0x${hash.toStr().substring(0, 8)}';
  }

  /// Compute 4-byte function selector from signature
  static String compute4BytesSignature(String functionSignature) {
    final hash =
        getKeccakDigest(Uint8List.fromList(functionSignature.codeUnits));
    return '0x${hash.toStr().substring(0, 8)}';
  }

  /// Get function name from transaction data
  String? getFunctionName(String hexData) {
    final selector = hexData.substring(0, 10).toLowerCase();
    return _functions[selector];
  }

  /// Get function signature from transaction data
  String? getFunctionSignature(String hexData) {
    final selector = hexData.substring(0, 10).toLowerCase();
    return _signatures[selector];
  }

  /// Decode function parameters from transaction data
  Map<String, dynamic>? decodeParameters(String hexData) {
    final selector = hexData.substring(0, 10).toLowerCase();
    final inputs = _functionInputs[selector];
    final functionName = _functions[selector];

    if (inputs == null || functionName == null) {
      return null;
    }

    // Remove function selector to get parameter data
    final paramData = hexData.substring(10);

    try {
      final decodedParams = _decodeParameters(inputs, paramData);
      return {
        'function': functionName,
        'signature': _signatures[selector],
        'parameters': decodedParams,
      };
    } catch (e, stackTrace) {
      return {
        'function': functionName,
        'signature': _signatures[selector],
        'error': 'Failed to decode parameters: $e',
        'stackTrace': stackTrace.toString(),
        'rawData': '0x$paramData',
      };
    }
  }

  /// Decode function parameters according to ABI encoding rules
  List<dynamic> _decodeParameters(List<dynamic> inputs, String hexData) {
    final List<dynamic> results = [];
    int offset = 0;

    for (int i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final type = input['type'] as String;
      final name = input['name'] as String? ?? 'param$i';

      if (type == 'tuple') {
        // Special handling for tuple types
        final components = input['components'] as List;
        if (_isTupleStatic(components)) {
          // Static tuple: decode directly at current position
          final tupleValue = _decodeStaticTuple(components, hexData, offset);
          results.add({
            'name': name,
            'type': type,
            'value': tupleValue,
          });
          offset += _getTupleStaticSize(components) * 2; // Each byte is 2 hex chars
        } else {
          // Dynamic tuple: read offset pointer
          final dynamicOffset = _readUint256FromHex(hexData, offset);
          final tupleValue = _decodeTuple(components, hexData, dynamicOffset * 2);
          results.add({
            'name': name,
            'type': type,
            'value': tupleValue,
          });
          offset += 64; // Offset pointer takes 32 bytes = 64 hex chars
        }
      } else if (_isStaticType(type)) {
        // Other static types decode directly at current position
        final value = _decodeStaticValue(type, hexData, offset, input);
        results.add({
          'name': name,
          'type': type,
          'value': value,
        });
        offset += _getStaticSize(type) * 2; // Each byte is 2 hex chars
      } else {
        // Dynamic types: read offset pointer
        final dynamicOffset = _readUint256FromHex(hexData, offset);
        final value = _decodeDynamicValue(type, hexData, dynamicOffset * 2, input);
        results.add({
          'name': name,
          'type': type,
          'value': value,
        });
        offset += 64; // Offset pointer takes 32 bytes = 64 hex chars
      }
    }

    return results;
  }

  /// Decode static tuple at specified offset
  List<dynamic> _decodeStaticTuple(
      List<dynamic> components, String hexData, int offset) {
    final List<dynamic> result = [];
    int currentOffset = offset;

    for (int i = 0; i < components.length; i++) {
      final component = components[i];
      final type = component['type'] as String;
      final name = component['name'] as String? ?? 'field$i';

      if (_isStaticType(type)) {
        final value = _decodeStaticValue(type, hexData, currentOffset, component);
        result.add({
          'name': name,
          'type': type,
          'value': value,
        });
        currentOffset += _getStaticSize(type) * 2; // Each byte is 2 hex chars
      } else {
        final dynamicOffset = _readUint256FromHex(hexData, currentOffset);
        final value = _decodeDynamicValue(
            type, hexData, offset + dynamicOffset * 2, component);
        result.add({
          'name': name,
          'type': type,
          'value': value,
        });
        currentOffset += 64; // Offset pointer takes 64 hex chars
      }
    }

    return result;
  }

  /// Check if type is static in ABI encoding
  bool _isStaticType(String type) {
    if (type.startsWith('uint') || type.startsWith('int')) return true;
    if (type == 'address') return true;
    if (type == 'bool') return true;
    if (type.startsWith('bytes') && type != 'bytes')
      return true; // Fixed-length bytes like bytes32
    return false;
  }

  /// Check if tuple is static (all components are static)
  bool _isTupleStatic(List<dynamic> components) {
    for (final component in components) {
      final componentType = component['type'] as String;
      if (!_isStaticType(componentType)) {
        return false;
      }
    }
    return true;
  }

  /// Get static type size in bytes
  int _getStaticSize(String type) {
    return 32; // Most static types in ABI take 32 bytes
  }

  /// Calculate total size of static tuple
  int _getTupleStaticSize(List<dynamic> components) {
    int size = 0;
    for (final component in components) {
      final componentType = component['type'] as String;
      if (_isStaticType(componentType)) {
        size += _getStaticSize(componentType);
      } else {
        size += 32; // Offset pointer for dynamic types
      }
    }
    return size;
  }

  /// Decode static value at specified offset
  dynamic _decodeStaticValue(
      String type, String hexData, int offset, dynamic input) {
    if (type == 'address') {
      // Address: skip first 24 hex chars (12 bytes), take next 40 hex chars (20 bytes)
      return '0x${hexData.substring(offset + 24, offset + 64)}';
    } else if (type.startsWith('uint')) {
      return _readUint256AsBigIntFromHex(hexData, offset);
    } else if (type.startsWith('int')) {
      return _readInt256AsBigIntFromHex(hexData, offset);
    } else if (type == 'bool') {
      return _readUint256FromHex(hexData, offset) != 0;
    } else if (type.startsWith('bytes') && type != 'bytes') {
      // Fixed-length bytes like bytes32
      return '0x${hexData.substring(offset, offset + 64)}';
    }
    return null;
  }

  /// Decode dynamic value at specified offset
  dynamic _decodeDynamicValue(
      String type, String hexData, int offset, dynamic input) {
    if (type == 'bytes') {
      final length = _readUint256FromHex(hexData, offset);
      if (length == 0) {
        return '0x';
      }
      final dataStart = offset + 64; // Skip length field (32 bytes = 64 hex chars)
      final dataEnd = dataStart + length * 2; // Each byte is 2 hex chars
      if (dataEnd > hexData.length) {
        return '0x'; // Return empty if out of bounds
      }
      return '0x${hexData.substring(dataStart, dataEnd)}';
    } else if (type == 'string') {
      final length = _readUint256FromHex(hexData, offset);
      if (length == 0) {
        return '';
      }
      final dataStart = offset + 64; // Skip length field
      final dataEnd = dataStart + length * 2; // Each byte is 2 hex chars
      if (dataEnd > hexData.length) {
        return '';
      }
      final hexString = hexData.substring(dataStart, dataEnd);
      // Convert hex string to bytes then to string
      final bytes = <int>[];
      for (int i = 0; i < hexString.length; i += 2) {
        bytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
      }
      return String.fromCharCodes(bytes);
    } else if (type == 'tuple') {
      return _decodeTuple(input['components'] as List, hexData, offset);
    }
    return null;
  }

  /// Decode tuple at specified offset (for dynamic tuples)
  List<dynamic> _decodeTuple(
      List<dynamic> components, String hexData, int offset) {
    final List<dynamic> result = [];
    int currentOffset = offset;

    for (int i = 0; i < components.length; i++) {
      final component = components[i];
      final type = component['type'] as String;
      final name = component['name'] as String? ?? 'field$i';

      if (_isStaticType(type)) {
        final value = _decodeStaticValue(type, hexData, currentOffset, component);
        result.add({
          'name': name,
          'type': type,
          'value': value,
        });
        currentOffset += _getStaticSize(type) * 2; // Each byte is 2 hex chars
      } else {
        final dynamicOffset = _readUint256FromHex(hexData, currentOffset);
        final value = _decodeDynamicValue(
            type, hexData, offset + dynamicOffset * 2, component);
        result.add({
          'name': name,
          'type': type,
          'value': value,
        });
        currentOffset += 64; // Offset pointer takes 64 hex chars
      }
    }

    return result;
  }

  /// Read uint256 value from hex string as int (for offsets and small numbers)
  int _readUint256FromHex(String hexData, int offset) {
    if (offset + 64 > hexData.length) {
      return 0;
    }

    final hexValue = hexData.substring(offset, offset + 64);

    // Check if high bytes are non-zero (would overflow int)
    final highPart = hexValue.substring(0, 48); // First 24 bytes = 48 hex chars
    if (highPart != '0' * 48) {
      return 0; // Return safe default for large numbers
    }

    // Read only low 8 bytes (16 hex chars)
    final lowPart = hexValue.substring(48);
    return int.parse(lowPart, radix: 16);
  }

  /// Read uint256 value from hex string as BigInt (for large numbers)
  BigInt _readUint256AsBigIntFromHex(String hexData, int offset) {
    if (offset + 64 > hexData.length) {
      return BigInt.zero;
    }

    final hexValue = hexData.substring(offset, offset + 64);
    return BigInt.parse(hexValue, radix: 16);
  }

  /// Read int256 value from hex string as BigInt (with sign handling)
  BigInt _readInt256AsBigIntFromHex(String hexData, int offset) {
    if (offset + 64 > hexData.length) {
      return BigInt.zero;
    }

    final hexValue = hexData.substring(offset, offset + 64);
    BigInt result = BigInt.parse(hexValue, radix: 16);

    // Handle sign bit (if MSB is 1, it's negative)
    final firstByte = int.parse(hexValue.substring(0, 2), radix: 16);
    if (firstByte >= 0x80) {
      // Calculate two's complement
      final maxValue = BigInt.one << 256;
      result = result - maxValue;
    }

    return result;
  }

  /// Check if function selector exists in ABI
  bool hasFunction(String selector) {
    return _functions.containsKey(selector.toLowerCase());
  }

  /// Get all available functions
  Map<String, String> get functions => Map.unmodifiable(_functions);

  /// Get all function signatures
  Map<String, String> get signatures => Map.unmodifiable(_signatures);
}
