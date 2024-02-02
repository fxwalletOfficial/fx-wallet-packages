import 'package:aleo_dart/src/rust_lib/programs_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:ffi/ffi.dart';

class AleoProgram {
  late ProgramsRustFFI programsRustFFI;

  AleoProgram(dyLib) {
    this.programsRustFFI = ProgramsRustFFI(dyLib);
  }

  String tryTransfer(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    int fee_credits,
    String url_raw,
    String amount_record_raw,
    String fee_record_raw,
  ) {
    final private_key = dartStrToC(private_key_raw);
    final transfer_type = dartStrToC(transfer_type_raw);
    final recipient = dartStrToC(recipient_raw);
    final url = dartStrToC(url_raw);
    final amount_record = dartStrToC(amount_record_raw);
    final fee_record = dartStrToC(fee_record_raw);

    return programsRustFFI
        .transfer(private_key, recipient, transfer_type, amount_credits,
            fee_credits, url, amount_record, fee_record)
        .toDartString();
  }
}

