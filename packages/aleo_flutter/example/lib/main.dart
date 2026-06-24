import 'package:flutter/material.dart';
import 'package:aleo_flutter/aleo_flutter.dart';

void main() => runApp(const AleoFlutterDemo());

class AleoFlutterDemo extends StatelessWidget {
  const AleoFlutterDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aleo_flutter example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Canonical bip39 test mnemonic — for the demo only, never a real wallet.
  static const _mnemonic = 'abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon abandon abandon about';

  String _status = 'Tap below to load the bundled native library and derive an '
      'address (a cheap, offline FFI call).';
  bool _ok = false;

  // Acceptance gate (PR6 spec §9): load the build-time-bundled aleo_rust library
  // and run one cheap, offline API. Driven by a tap (not initState) so app
  // launch and the widget test do not require the native library to be present.
  void _run() {
    setState(() {
      _status = 'Running…';
      _ok = false;
    });
    try {
      final lib = AleoFlutter.load(); // validates ffi_abi_version at load
      final account = AleoAccount(lib, 'mainnet');
      final address = account.mnemonicToAddress(_mnemonic);
      setState(() {
        _ok = true;
        _status = 'OK — bundled aleo_rust loaded and ABI validated.\n\n'
            'mnemonicToAddress (mainnet):\n$address';
      });
    } on IncompatibleNativeLibraryException catch (e) {
      setState(() => _status = 'ABI mismatch:\n$e');
    } catch (e) {
      setState(() => _status = 'Failed:\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('aleo_flutter example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: const Key('run'),
              onPressed: _run,
              icon: const Icon(Icons.bolt),
              label: const Text('Load & derive address'),
            ),
            const SizedBox(height: 24),
            Icon(
              _ok ? Icons.check_circle : Icons.bolt_outlined,
              color: _ok ? Colors.green : Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
