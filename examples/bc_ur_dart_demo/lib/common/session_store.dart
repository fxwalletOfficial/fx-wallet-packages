import 'package:flutter/foundation.dart';

/// Sprint 3 签名两步流程：Step1 把 requestId 写入，Step2 扫描后取出校验。
class SessionStore extends ChangeNotifier {
  String? _currentRequestId;
  String? _currentCoinType;
  Map<String, dynamic>? _currentSignRequest;

  String? get currentRequestId => _currentRequestId;
  String? get currentCoinType => _currentCoinType;
  Map<String, dynamic>? get currentSignRequest => _currentSignRequest;
  bool get hasActiveSession => _currentRequestId != null;

  void startSignSession({
    required String requestId,
    required String coinType,
    required Map<String, dynamic> signRequest,
  }) {
    _currentRequestId = requestId;
    _currentCoinType = coinType;
    _currentSignRequest = signRequest;
    notifyListeners();
  }

  void clearSignSession() {
    _currentRequestId = null;
    _currentCoinType = null;
    _currentSignRequest = null;
    notifyListeners();
  }
}
