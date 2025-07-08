import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter_web3_webview/src/config/params.dart';
import 'package:flutter_web3_webview/src/models/js_callback_data.dart';
import 'package:flutter_web3_webview/src/models/settings.dart';
import 'package:flutter_web3_webview/src/utils/provider.dart';

/// Webview to support wallet connect to web3 DApp. Use webview supported by Flutter_inappwebview.
class Web3Webview extends StatefulWidget {
  /// Web3 settings for eth, sol.
  final Web3Settings? settings;

  /// Whether inject provider for web3 DApp.
  final bool isWeb3;

  final int? windowId;
  final URLRequest? initialUrlRequest;
  final InAppWebViewSettings? initialSettings;
  final bool? preventGestureDelay;
  final HeadlessInAppWebView? headlessWebView;
  final InAppWebViewKeepAlive? keepAlive;
  final TextDirection? layoutDirection;
  final InAppWebViewInitialData? initialData;
  final String? initialFile;
  final List<UserScript>? initialUserScripts;
  final ContextMenu? contextMenu;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final FindInteractionController? findInteractionController;
  final PullToRefreshController? pullToRefreshController;
  final void Function(InAppWebViewController)? onWebViewCreated;
  final Future<PermissionResponse?> Function(
          InAppWebViewController controller, PermissionRequest request)?
      onPermissionRequest;
  final void Function(InAppWebViewController controller, int value)?
      onProgressChanged;
  final void Function(InAppWebViewController controller, String? value)?
      onTitleChanged;
  final void Function(
          InAppWebViewController controller, WebUri? uri, bool? isReload)?
      onUpdateVisitedHistory;
  final void Function(InAppWebViewController controller, WebUri? uri)?
      onLoadStart;
  final void Function(InAppWebViewController controller, WebUri? uri)?
      onLoadStop;
  final void Function(InAppWebViewController controller,
      WebResourceRequest request, WebResourceError error)? onReceivedError;
  final void Function(
          InAppWebViewController controller, ConsoleMessage message)?
      onConsoleMessage;
  final Future<bool> Function(
          InAppWebViewController controller, CreateWindowAction action)?
      onCreateWindow;
  final Future<NavigationActionPolicy?> Function(
          InAppWebViewController, NavigationAction action)?
      shouldOverrideUrlLoading;
  final void Function(InAppWebViewController controller, WebUri? url)?
      onPageCommitVisible;
  final Future<AjaxRequestAction> Function(
          InAppWebViewController controller, AjaxRequest ajaxRequest)?
      onAjaxProgress;
  final Future<AjaxRequestAction?> Function(
          InAppWebViewController controller, AjaxRequest ajaxRequest)?
      onAjaxReadyStateChange;
  final void Function(InAppWebViewController controller)? onCloseWindow;
  final void Function(InAppWebViewController controller)? onWindowFocus;
  final void Function(InAppWebViewController controller)? onWindowBlur;
  final void Function(InAppWebViewController controller,
      DownloadStartRequest downloadStartRequest)? onDownloadStartRequest;
  final Future<JsAlertResponse?> Function(
          InAppWebViewController controller, JsAlertRequest jsAlertRequest)?
      onJsAlert;
  final Future<JsConfirmResponse?> Function(
          InAppWebViewController controller, JsConfirmRequest jsConfirmRequest)?
      onJsConfirm;
  final Future<JsPromptResponse?> Function(
          InAppWebViewController controller, JsPromptRequest jsPromptRequest)?
      onJsPrompt;
  final void Function(
      InAppWebViewController controller,
      WebResourceRequest request,
      WebResourceResponse errorResponse)? onReceivedHttpError;
  final void Function(
          InAppWebViewController controller, LoadedResource resource)?
      onLoadResource;
  final Future<CustomSchemeResponse?> Function(
          InAppWebViewController controller, WebResourceRequest request)?
      onLoadResourceWithCustomScheme;
  final void Function(InAppWebViewController controller,
      InAppWebViewHitTestResult hitTestResult)? onLongPressHitTestResult;
  final Future<bool?> Function(InAppWebViewController controller, WebUri? url,
      PlatformPrintJobController? printJobController)? onPrintRequest;
  final Future<ClientCertResponse?> Function(InAppWebViewController controller,
      URLAuthenticationChallenge challenge)? onReceivedClientCertRequest;
  final Future<HttpAuthResponse?> Function(InAppWebViewController controller,
      URLAuthenticationChallenge challenge)? onReceivedHttpAuthRequest;
  final Future<ServerTrustAuthResponse?> Function(
      InAppWebViewController controller,
      URLAuthenticationChallenge challenge)? onReceivedServerTrustAuthRequest;
  final void Function(InAppWebViewController controller, int x, int y)?
      onScrollChanged;
  final Future<AjaxRequest?> Function(
          InAppWebViewController controller, AjaxRequest ajaxRequest)?
      shouldInterceptAjaxRequest;
  final Future<FetchRequest?> Function(
          InAppWebViewController controller, FetchRequest fetchRequest)?
      shouldInterceptFetchRequest;
  final void Function(InAppWebViewController controller)? onEnterFullScreen;
  final void Function(InAppWebViewController controller)? onExitFullScreen;
  final void Function(InAppWebViewController controller, int x, int y,
      bool clampedX, bool clampedY)? onOverScrolled;
  final void Function(
          InAppWebViewController controller, double oldScale, double newScale)?
      onZoomScaleChanged;
  final void Function(InAppWebViewController controller)?
      onDidReceiveServerRedirectForProvisionalNavigation;
  final Future<FormResubmissionAction?> Function(
      InAppWebViewController controller, WebUri? url)? onFormResubmission;
  final void Function(InAppWebViewController controller)?
      onGeolocationPermissionsHidePrompt;
  final Future<GeolocationPermissionShowPromptResponse?> Function(
          InAppWebViewController controller, String origin)?
      onGeolocationPermissionsShowPrompt;
  final Future<JsBeforeUnloadResponse?> Function(
      InAppWebViewController controller,
      JsBeforeUnloadRequest jsBeforeUnloadRequest)? onJsBeforeUnload;
  final Future<NavigationResponseAction?> Function(
      InAppWebViewController controller,
      NavigationResponse navigationResponse)? onNavigationResponse;
  final void Function(InAppWebViewController controller, Uint8List icon)?
      onReceivedIcon;
  final void Function(
          InAppWebViewController controller, LoginRequest loginRequest)?
      onReceivedLoginRequest;
  final void Function(InAppWebViewController controller,
      PermissionRequest permissionRequest)? onPermissionRequestCanceled;
  final void Function(InAppWebViewController controller)? onRequestFocus;
  final void Function(
          InAppWebViewController controller, WebUri url, bool precomposed)?
      onReceivedTouchIconUrl;
  final void Function(
          InAppWebViewController controller, RenderProcessGoneDetail detail)?
      onRenderProcessGone;
  final Future<WebViewRenderProcessAction?> Function(
          InAppWebViewController controller, WebUri? url)?
      onRenderProcessResponsive;
  final Future<WebViewRenderProcessAction?> Function(
          InAppWebViewController controller, WebUri? url)?
      onRenderProcessUnresponsive;
  final Future<SafeBrowsingResponse?> Function(
      InAppWebViewController controller,
      WebUri url,
      SafeBrowsingThreat? threatType)? onSafeBrowsingHit;
  final void Function(InAppWebViewController controller)?
      onWebContentProcessDidTerminate;
  final Future<ShouldAllowDeprecatedTLSAction?> Function(
      InAppWebViewController controller,
      URLAuthenticationChallenge challenge)? shouldAllowDeprecatedTLS;
  final Future<WebResourceResponse?> Function(
          InAppWebViewController controller, WebResourceRequest request)?
      shouldInterceptRequest;
  final Future<void> Function(
      InAppWebViewController controller,
      MediaCaptureState? oldState,
      MediaCaptureState? newState)? onCameraCaptureStateChanged;
  final Future<void> Function(
    InAppWebViewController controller,
    MediaCaptureState? oldState,
    MediaCaptureState? newState,
  )? onMicrophoneCaptureStateChanged;
  final void Function(InAppWebViewController controller, Size oldContentSize,
      Size newContentSize)? onContentSizeChanged;

  final Future<List<String>> Function()? ethAccounts;
  final Future<int> Function()? ethChainId;
  final Future<String> Function(JsTransactionObject data)? ethSendTransaction;
  final Future<String> Function(String data)? ethSign;
  final Future<String> Function(String data)? ethPersonalSign;
  final Future<String> Function(String data)? ethSignTypedData;
  final Future<bool> Function(JsAddEthereumChain data)?
      walletSwitchEthereumChain;
  final Future<String> Function()? solAccount;
  final Future<String> Function(JsCallBackData data)? solSignTransaction;
  final Future<String> Function(JsCallBackData data)? solSignMessage;
  final Future<dynamic> Function(JsCallBackData data)? onDefaultCallback;

  const Web3Webview(
      {super.key,
      this.settings,
      this.isWeb3 = true,
      this.windowId,
      this.initialUrlRequest,
      this.initialSettings,
      this.preventGestureDelay,
      this.headlessWebView,
      this.keepAlive,
      this.layoutDirection,
      this.initialData,
      this.initialFile,
      this.initialUserScripts,
      this.contextMenu,
      this.gestureRecognizers,
      this.findInteractionController,
      this.pullToRefreshController,
      this.onWebViewCreated,
      this.onPermissionRequest,
      this.onProgressChanged,
      this.onTitleChanged,
      this.onUpdateVisitedHistory,
      this.onLoadStart,
      this.onLoadStop,
      this.onReceivedError,
      this.onConsoleMessage,
      this.onCreateWindow,
      this.shouldOverrideUrlLoading,
      this.onPageCommitVisible,
      this.onAjaxProgress,
      this.onAjaxReadyStateChange,
      this.onCloseWindow,
      this.onWindowFocus,
      this.onWindowBlur,
      this.onDownloadStartRequest,
      this.onJsAlert,
      this.onJsConfirm,
      this.onJsPrompt,
      this.onReceivedHttpError,
      this.onLoadResource,
      this.onLoadResourceWithCustomScheme,
      this.onLongPressHitTestResult,
      this.onPrintRequest,
      this.onReceivedClientCertRequest,
      this.onReceivedHttpAuthRequest,
      this.onReceivedServerTrustAuthRequest,
      this.onScrollChanged,
      this.shouldInterceptAjaxRequest,
      this.shouldInterceptFetchRequest,
      this.onEnterFullScreen,
      this.onExitFullScreen,
      this.onOverScrolled,
      this.onZoomScaleChanged,
      this.onDidReceiveServerRedirectForProvisionalNavigation,
      this.onFormResubmission,
      this.onGeolocationPermissionsHidePrompt,
      this.onGeolocationPermissionsShowPrompt,
      this.onJsBeforeUnload,
      this.onNavigationResponse,
      this.onReceivedIcon,
      this.onReceivedLoginRequest,
      this.onPermissionRequestCanceled,
      this.onRequestFocus,
      this.onReceivedTouchIconUrl,
      this.onRenderProcessGone,
      this.onRenderProcessResponsive,
      this.onRenderProcessUnresponsive,
      this.onSafeBrowsingHit,
      this.onWebContentProcessDidTerminate,
      this.shouldAllowDeprecatedTLS,
      this.shouldInterceptRequest,
      this.onCameraCaptureStateChanged,
      this.onMicrophoneCaptureStateChanged,
      this.onContentSizeChanged,
      this.ethAccounts,
      this.ethChainId,
      this.ethSendTransaction,
      this.ethSign,
      this.ethPersonalSign,
      this.ethSignTypedData,
      this.walletSwitchEthereumChain,
      this.solAccount,
      this.solSignTransaction,
      this.solSignMessage,
      this.onDefaultCallback});

  @override
  Web3WebviewState createState() => Web3WebviewState();

  static Future<void> initJs() => Providers.init();
}

class Web3WebviewState extends State<Web3Webview> {
  bool get isWeb3 => widget.isWeb3;
  /// Event from dapp.
  final List<Function> _eventQueue = [];
  /// Completers match with every event.
  final List<Completer<dynamic>> _completers = [];
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
        windowId: widget.windowId,
        initialUrlRequest: widget.initialUrlRequest,
        initialSettings: widget.initialSettings ?? DEFAULT_SETTINGS,
        preventGestureDelay: widget.preventGestureDelay,
        headlessWebView: widget.headlessWebView,
        keepAlive: widget.keepAlive,
        layoutDirection: widget.layoutDirection,
        initialData: widget.initialData,
        initialFile: widget.initialFile,
        initialUserScripts: UnmodifiableListView([
              UserScript(
                  source: Providers.js,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
              UserScript(
                  source: Providers(settings: widget.settings).getInitJs(),
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START)
            ] +
            (widget.initialUserScripts ?? [])),
        contextMenu: widget.contextMenu,
        gestureRecognizers: widget.gestureRecognizers,
        findInteractionController: widget.findInteractionController,
        pullToRefreshController: widget.pullToRefreshController,
        onWebViewCreated: _onWebViewCreated,
        onPermissionRequest:
            widget.onPermissionRequest ?? DEFAULT_PERMISSION_REQUEST,
        onProgressChanged: widget.onProgressChanged,
        onTitleChanged: widget.onTitleChanged,
        onUpdateVisitedHistory: widget.onUpdateVisitedHistory,
        onLoadStart: widget.onLoadStart,
        onLoadStop: widget.onLoadStop,
        onReceivedError: widget.onReceivedError,
        onConsoleMessage: widget.onConsoleMessage,
        onCreateWindow: widget.onCreateWindow,
        shouldOverrideUrlLoading: widget.shouldOverrideUrlLoading,
        onPageCommitVisible: widget.onPageCommitVisible,
        onAjaxProgress: widget.onAjaxProgress,
        onCloseWindow: widget.onCloseWindow,
        onWindowFocus: widget.onWindowFocus,
        onWindowBlur: widget.onWindowBlur,
        onDownloadStartRequest: widget.onDownloadStartRequest,
        onJsAlert: widget.onJsAlert,
        onJsConfirm: widget.onJsConfirm,
        onJsPrompt: widget.onJsPrompt,
        onReceivedHttpError: widget.onReceivedHttpError,
        onLoadResource: widget.onLoadResource,
        onLoadResourceWithCustomScheme: widget.onLoadResourceWithCustomScheme,
        onLongPressHitTestResult: widget.onLongPressHitTestResult,
        onPrintRequest: widget.onPrintRequest,
        onReceivedClientCertRequest: widget.onReceivedClientCertRequest,
        onReceivedHttpAuthRequest: widget.onReceivedHttpAuthRequest,
        onReceivedServerTrustAuthRequest:
            widget.onReceivedServerTrustAuthRequest,
        onScrollChanged: widget.onScrollChanged,
        shouldInterceptAjaxRequest: widget.shouldInterceptAjaxRequest,
        shouldInterceptFetchRequest: widget.shouldInterceptFetchRequest,
        onEnterFullscreen: widget.onEnterFullScreen,
        onExitFullscreen: widget.onExitFullScreen,
        onOverScrolled: widget.onOverScrolled,
        onZoomScaleChanged: widget.onZoomScaleChanged,
        onDidReceiveServerRedirectForProvisionalNavigation:
            widget.onDidReceiveServerRedirectForProvisionalNavigation,
        onFormResubmission: widget.onFormResubmission,
        onGeolocationPermissionsHidePrompt:
            widget.onGeolocationPermissionsHidePrompt,
        onGeolocationPermissionsShowPrompt:
            widget.onGeolocationPermissionsShowPrompt,
        onJsBeforeUnload: widget.onJsBeforeUnload,
        onNavigationResponse: widget.onNavigationResponse,
        onReceivedIcon: widget.onReceivedIcon,
        onReceivedLoginRequest: widget.onReceivedLoginRequest,
        onPermissionRequestCanceled: widget.onPermissionRequestCanceled,
        onRequestFocus: widget.onRequestFocus,
        onReceivedTouchIconUrl: widget.onReceivedTouchIconUrl,
        onRenderProcessGone: widget.onRenderProcessGone,
        onRenderProcessResponsive: widget.onRenderProcessResponsive,
        onRenderProcessUnresponsive: widget.onRenderProcessUnresponsive,
        onSafeBrowsingHit: widget.onSafeBrowsingHit,
        onWebContentProcessDidTerminate: widget.onWebContentProcessDidTerminate,
        shouldAllowDeprecatedTLS: widget.shouldAllowDeprecatedTLS,
        shouldInterceptRequest: widget.shouldInterceptRequest,
        onCameraCaptureStateChanged: widget.onCameraCaptureStateChanged,
        onMicrophoneCaptureStateChanged: widget.onMicrophoneCaptureStateChanged,
        onContentSizeChanged: widget.onContentSizeChanged);
  }

  void _onWebViewCreated(InAppWebViewController controller) {
    if (widget.onWebViewCreated != null) widget.onWebViewCreated!(controller);

    if (controller.hasJavaScriptHandler(handlerName: 'FxWalletHandler')) return;
    controller.addJavaScriptHandler(
      handlerName: 'FxWalletHandler',
      callback: (args) async {
        final item = JsCallBackData.fromData(args);

        // If the event is getting accounts or chain id, execute immediately.
        if (checkMethod(item.method)) return _onHandleCallback(item, controller)();

        // Else add it to event queue.
        try {
          final results = await Future.wait([_addEvent(_onHandleCallback(item, controller)), getLastCompleter()], eagerError: true);
          return results.last;
        } catch (e) {
          rethrow;
        }
      }
    );
  }

  /// Get the last completer.
  Future<dynamic> getLastCompleter() async {
    final completer = _completers.last;
    final result = await completer.future;
    return result;
  }

  /// Event queueing method.
  Future<void> _addEvent(Function event) async {
    _eventQueue.insert(0, event);
    _completers.insert(0, Completer<dynamic>());

    if (_isProcessing) return;
    _isProcessing = true;

    while (_eventQueue.isNotEmpty && _completers.isNotEmpty) {
      try {
        final completer = _completers.last;
        final result = await _eventQueue.last();
        completer.complete(result);
      } catch (e) {
        _isProcessing = false;
        rethrow;
      } finally {
        _eventQueue.removeLast();
        _completers.removeLast();
      }
    }

    _isProcessing = false;
  }

  /// Handle handler callback from DApp.
  Function _onHandleCallback(JsCallBackData args, InAppWebViewController controller) {
    try {
      switch (args.method) {
        case 'eth_accounts':
        case 'eth_requestAccounts':
        return _ethAccounts;

      case 'eth_chainId':
        return _ethChainId;

      case 'wallet_switchEthereumChain':
      case 'wallet_addEthereumChain':
        return () => _walletSwitchEthereumChain(args, controller);

      case 'solana_account':
        return _solAccount;

      case 'eth_sendTransaction':
        return () => _ethSendTransaction(args);

      case 'eth_sign':
        return () => _ethSign(args);

      case 'personal_sign':
        return () => _personalSign(args);

      case 'eth_signTypedData':
      case 'eth_signTypedData_v3':
      case 'eth_signTypedData_v4':
        return () => _ethSignTypedData(args);

      case 'solana_signTransaction':
        return () => _solSignTransaction(args);

      case 'solana_signMessage':
        return () => _solSignMessage(args);

      default:
        return () => _onDefaultCallback(args);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get eth account.
  Future<List<String>> _ethAccounts() async {
    if (widget.ethAccounts == null) throw Exception('Invalid wallet');
    return widget.ethAccounts!();
  }

  /// Get eth chain id.
  Future<String> _ethChainId() async {
    if (widget.ethChainId == null) throw Exception('Invalid wallet');

    final id = await widget.ethChainId!();
    return '0x${id.toRadixString(16)}';
  }

  /// Sign and broadcast eth transaction.
  Future<String> _ethSendTransaction(JsCallBackData data) async {
    if (widget.ethSendTransaction == null) throw Exception('Invalid wallet');

    final params = data.getTxParams();
    return widget.ethSendTransaction!(params);
  }

  /// Eth sign.
  Future<String> _ethSign(JsCallBackData data) async {
    if (widget.ethSign == null) throw Exception('Invalid wallet');

    final params = data.getEthSignMsg();
    return widget.ethSign!(params);
  }

  /// Eth personal sign.
  Future<String> _personalSign(JsCallBackData data) async {
    if (widget.ethPersonalSign == null) throw Exception('Invalid wallet');

    final params = data.getPersonalSignMsg();
    return widget.ethPersonalSign!(params);
  }

  /// Eth sign typed data.
  Future<String> _ethSignTypedData(JsCallBackData data) async {
    if (widget.ethSignTypedData == null) throw Exception('Invalid wallet');

    final params = data.getSignTypedDataParams();
    return widget.ethSignTypedData!(params);
  }

  /// Switch or add eth chain.
  Future<String> _walletSwitchEthereumChain(
      JsCallBackData data, InAppWebViewController controller) async {
    if (widget.walletSwitchEthereumChain == null) {
      throw Exception('Invalid wallet');
    }

    final params = data.getChainParams();
    final result = await widget.walletSwitchEthereumChain!(params);
    if (!result) throw Exception({'code': 4092});

    await controller.evaluateJavascript(
        source: 'window.ethereum.emitChainChanged(${params.chainId})');
    return _ethChainId();
  }

  /// Get sol account.
  Future<String> _solAccount() async {
    if (widget.solAccount == null) throw Exception('Invalid wallet');
    return widget.solAccount!();
  }

  /// Sign sol transaction.
  Future<String> _solSignTransaction(JsCallBackData data) async {
    if (widget.solSignTransaction == null) throw Exception('Invalid wallet');
    return widget.solSignTransaction!(data);
  }

  /// Sign sol message.
  Future<String> _solSignMessage(JsCallBackData data) async {
    if (widget.solSignMessage == null) throw Exception('Invalid wallet');
    return widget.solSignMessage!(data);
  }

  /// Handle other callback.
  Future<dynamic> _onDefaultCallback(JsCallBackData data) async {
    if (widget.onDefaultCallback == null) throw Exception('Invalid wallet');
    return widget.onDefaultCallback!(data);
  }

  bool checkMethod(String method) {
    const List<String> accountMethods = [
      'eth_accounts',
      'eth_requestAccounts',
      'eth_chainId',
      'wallet_switchEthereumChain',
      'wallet_addEthereumChain',
      'solana_account'
    ];

    return accountMethods.contains(method);
  }
}
