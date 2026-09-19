import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const _maxResponseBodyBytes = 64 * 1024;

/// One authenticated subscription synchronization request.
class FxPushSubscriptionRequest {
  /// Creates a request for a custom or HTTP transport.
  const FxPushSubscriptionRequest({
    required this.registrationKey,
    required this.body,
  });

  /// Bearer registration credential; transports must never log it.
  final String registrationKey;

  /// Validated JSON-compatible subscription state.
  final Map<String, Object> body;
}

/// Validated subscription state returned by the service.
class FxPushSubscriptionResponse {
  /// Creates a transport response.
  const FxPushSubscriptionResponse({
    required this.subscriptionId,
    required this.revision,
    required this.active,
  });

  /// Stable subscription identifier, or `null` for a no-op first disable.
  final String? subscriptionId;

  /// Non-negative decimal service revision.
  final String revision;

  /// Active state confirmed by the service.
  final bool active;
}

/// Transport boundary used by the subscription client.
abstract interface class FxPushSubscriptionTransport {
  /// Synchronizes one complete desired subscription state.
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  );
}

/// A non-successful HTTP response from the subscription service.
class FxPushHttpException implements Exception {
  /// Creates a bounded HTTP error without retaining a raw response body.
  const FxPushHttpException({
    required this.statusCode,
    this.code,
    this.message,
    this.retryAfter,
  });

  /// HTTP response status.
  final int statusCode;

  /// Optional structured service error code.
  final String? code;

  /// Optional structured service message.
  final String? message;

  /// Optional server-requested minimum retry delay.
  final Duration? retryAfter;

  /// Whether the client may retry this response.
  bool get isRetryable => statusCode == 429 || statusCode >= 500;

  @override
  String toString() =>
      'FxPushHttpException(statusCode: $statusCode, code: $code)';
}

/// A successful HTTP response that violates the subscription protocol.
class FxPushProtocolException implements Exception {
  /// Creates a bounded protocol error.
  const FxPushProtocolException(this.message);

  /// Explanation that does not include provider tokens or credentials.
  final String message;

  @override
  String toString() => 'FxPushProtocolException($message)';
}

/// HTTPS transport for `POST /device/v1/subscriptions`.
class FxPushHttpTransport implements FxPushSubscriptionTransport {
  /// Creates the default HTTPS transport.
  FxPushHttpTransport({
    required Uri serviceUrl,
    this.connectionTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 15),
  }) : _serviceUrl = _validateServiceUrl(serviceUrl);

  final Uri _serviceUrl;

  /// TCP connection timeout.
  final Duration connectionTimeout;

  /// Timeout for each request, response, and response-body operation.
  final Duration requestTimeout;

  static Uri _validateServiceUrl(Uri url) {
    if (url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment ||
        (url.path.isNotEmpty && url.path != '/')) {
      throw ArgumentError.value(
        url,
        'serviceUrl',
        'must be an HTTPS origin without credentials, path, query, or fragment',
      );
    }
    return url;
  }

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest enrollment,
  ) async {
    final client = HttpClient()..connectionTimeout = connectionTimeout;
    try {
      final request = await client
          .postUrl(_serviceUrl.resolve('/device/v1/subscriptions'))
          .timeout(requestTimeout);
      request
        ..followRedirects = false
        ..headers.contentType = ContentType.json
        ..headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${enrollment.registrationKey}',
        )
        ..write(jsonEncode(enrollment.body));
      final response = await request.close().timeout(requestTimeout);
      final raw = await _readResponseBody(response).timeout(requestTimeout);

      if (response.statusCode != HttpStatus.ok) {
        final error = _tryDecodeObject(raw)['error'];
        final errorObject = error is Map
            ? Map<String, Object?>.from(error)
            : const <String, Object?>{};
        throw FxPushHttpException(
          statusCode: response.statusCode,
          code: errorObject['code'] is String
              ? errorObject['code']! as String
              : null,
          message: errorObject['message'] is String
              ? errorObject['message']! as String
              : null,
          retryAfter: _retryAfter(response.headers),
        );
      }

      final body = _decodeObject(raw);
      final subscriptionId = body['subscription_id'];
      final revision = body['revision'];
      final active = body['active'];
      if (subscriptionId != null &&
              (subscriptionId is! String || !_isUuid(subscriptionId)) ||
          revision is! String ||
          !RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(revision) ||
          active is! bool) {
        throw const FxPushProtocolException('invalid subscription response');
      }
      return FxPushSubscriptionResponse(
        subscriptionId: subscriptionId as String?,
        revision: revision,
        active: active,
      );
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, Object?> _decodeObject(String raw) {
    if (raw.isEmpty) return const <String, Object?>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } on FormatException {
      // Converted below to a bounded protocol error without logging the body.
    }
    throw const FxPushProtocolException('response is not a JSON object');
  }

  static Future<String> _readResponseBody(HttpClientResponse response) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (bytes.length + chunk.length > _maxResponseBodyBytes) {
        throw const FxPushProtocolException(
          'response body exceeds 65536 bytes',
        );
      }
      bytes.add(chunk);
    }
    try {
      return utf8.decode(bytes.takeBytes());
    } on FormatException {
      throw const FxPushProtocolException('response body is not valid UTF-8');
    }
  }

  static Map<String, Object?> _tryDecodeObject(String raw) {
    try {
      return _decodeObject(raw);
    } on FxPushProtocolException {
      return const <String, Object?>{};
    }
  }

  static Duration? _retryAfter(HttpHeaders headers) {
    final value = headers.value(HttpHeaders.retryAfterHeader);
    final seconds = int.tryParse(value ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);
}
