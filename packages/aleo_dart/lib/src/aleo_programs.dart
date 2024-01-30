
import 'package:aleo_dart/src/rust_lib/programs_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:ffi/ffi.dart';

String buildTransferTransaction(
    String private_key_raw,
    double amount_credits,
    String transfer_type_raw,
    String recipient_raw,
    double fee_credits,
    String url_raw) {
  final private_key = dartStrToC(private_key_raw);
  final transfer_type = dartStrToC(transfer_type_raw);
  final recipient = dartStrToC(recipient_raw);
  final url = dartStrToC(url_raw);

  return ProgramsRustFFI.buildTransferTransaction(private_key, amount_credits,
          transfer_type, recipient, fee_credits, url)
      .toDartString();
}