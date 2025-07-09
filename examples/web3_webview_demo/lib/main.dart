import 'package:flutter/material.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Web3Webview.initJs();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true
      ),
      home: const Page()
    );
  }
}

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  PageState createState() => PageState();
}

class PageState extends State<Page> {
  String _title = '';
  int _chainId = 1;

  String ethAddress = '0x0731fE5077B6aD30E8Cf9eeE3FC4b6D1410702Bb';
  String ethPrivateKey = '0x56d2380a81a9cdec89159b912cd19f681f51381aab2fd323a87085ab7aa884cc';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Web3Webview(
        initialUrlRequest: URLRequest(url: WebUri('https://app.uniswap.org')),
        settings: Web3Settings(
          eth: Web3EthSettings(
            chainId: _chainId,
            rdns: 'com.fxfi.fxwallet'
          )
        ),
        shouldOverrideUrlLoading: (p0, action) async => NavigationActionPolicy.ALLOW,
        onTitleChanged: _onTitleChanged,
        ethAccounts: _ethAccounts,
        ethChainId: _ethChainId,
        walletSwitchEthereumChain: _walletSwitchEthereumChain
      )
    );
  }

  void _onTitleChanged(InAppWebViewController c, String? value) {
    if (value == null || value == _title) return;

    _title = value;
    setState(() { });
  }

  Future<int> _ethChainId() async {
    return _chainId;
  }

  Future<List<String>> _ethAccounts() async {
    return [ethAddress];
  }

  Future<bool> _walletSwitchEthereumChain(JsAddEthereumChain data) async {
    _chainId = int.parse((data.chainId)?.replaceFirst('0x', '') ?? '1', radix: 16);
    return true;
  }
}
