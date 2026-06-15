import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FakeInAppWebViewPlatform extends InAppWebViewPlatform {
  final List<FakePlatformInAppWebViewWidget> widgets = [];

  FakePlatformInAppWebViewController? get lastController =>
      widgets.isEmpty ? null : widgets.last.controller;

  PlatformInAppWebViewWidgetCreationParams? get lastParams =>
      widgets.isEmpty ? null : widgets.last.params;

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    final widget = FakePlatformInAppWebViewWidget(params);
    widgets.add(widget);
    return widget;
  }
}

class FakePlatformInAppWebViewWidget extends PlatformInAppWebViewWidget {
  final FakePlatformInAppWebViewController controller;
  bool _created = false;

  FakePlatformInAppWebViewWidget(super.params)
      : controller = FakePlatformInAppWebViewController(),
        super.implementation();

  @override
  Widget build(BuildContext context) {
    if (!_created) {
      _created = true;
      final publicController = controllerFromPlatform(controller);
      params.onWebViewCreated?.call(publicController);
    }
    return const SizedBox();
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) {
    return params.controllerFromPlatform!(controller) as T;
  }

  @override
  void dispose() {}
}

class FakePlatformInAppWebViewController
    extends PlatformInAppWebViewController {
  final Map<String, JavaScriptHandlerCallback> handlers = {};
  final List<String> evaluatedScripts = [];

  FakePlatformInAppWebViewController()
      : super.implementation(
          const PlatformInAppWebViewControllerCreationParams(id: 1),
        );

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    handlers[handlerName] = callback;
  }

  @override
  bool hasJavaScriptHandler({required String handlerName}) {
    return handlers.containsKey(handlerName);
  }

  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    evaluatedScripts.add(source);
  }
}
