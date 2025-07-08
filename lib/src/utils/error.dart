class URException implements Exception {
  final URExceptionType type;
  final String message;

  URException({required this.type, required this.message});

  @override
  String toString() => '[UR ERROR] - ${type.toPrettyDescription()}: $message.';
}

class InvalidFormatURException extends URException {
  InvalidFormatURException({required String input}) : super(type: URExceptionType.invalidFormat, message: input);
}

class InvalidSequenceURException extends URException {
  InvalidSequenceURException({required String value}) : super(type: URExceptionType.invalidFormat, message: value);
}

enum URExceptionType {
  invalidFormat,
  invalidSequence,
  invalidType,
  invalidParams
}

extension _URExceptionTypeExtension on URExceptionType {
  String toPrettyDescription() {
    switch (this) {
      case URExceptionType.invalidFormat:
        return 'Invalid Format';
      case URExceptionType.invalidSequence:
        return 'Invalid Sequence';
      case URExceptionType.invalidType:
        return 'Invalid Type';
      case URExceptionType.invalidParams:
        return 'Invalid Params';
    }
  }
}
