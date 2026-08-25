import 'sc_wasm_flutter_consumer_test_io.dart'
    if (dart.library.ui) 'sc_wasm_flutter_consumer_test_flutter.dart'
    as test_impl;

void main() {
  test_impl.run();
}
