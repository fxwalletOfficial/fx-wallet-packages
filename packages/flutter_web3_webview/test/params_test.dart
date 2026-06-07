import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/config/params.dart';

void main() {
  test('default WebView settings enable required browser capabilities', () {
    expect(DEFAULT_SETTINGS.javaScriptCanOpenWindowsAutomatically, isTrue);
    expect(DEFAULT_SETTINGS.supportMultipleWindows, isTrue);
    expect(DEFAULT_SETTINGS.allowsInlineMediaPlayback, isTrue);
  });

  test('default permission handler denies requested resources', () async {
    final resources = [
      PermissionResourceType.CAMERA,
      PermissionResourceType.MICROPHONE,
    ];
    final request = PermissionRequest(
      origin: WebUri('https://example.com'),
      resources: resources,
    );

    final response = await DEFAULT_PERMISSION_REQUEST(
      InAppWebViewController.fromPlatform(platform: _FakePlatformController()),
      request,
    );

    expect(response?.action, PermissionResponseAction.DENY);
    expect(response?.resources, same(resources));
  });

  test('default wallet metadata is populated', () {
    expect(WALLET_NAME, isNotEmpty);
    expect(WALLET_ICON, startsWith('data:image/svg+xml;base64,'));
  });
}

class _FakePlatformController extends PlatformInAppWebViewController {
  _FakePlatformController()
      : super.implementation(
          const PlatformInAppWebViewControllerCreationParams(id: 1),
        );
}
