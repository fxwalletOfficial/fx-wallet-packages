import 'package:flutter/material.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

import 'package:web3_webview_demo/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Web3Webview.initJs();

  runApp(const DemoApp());
}
