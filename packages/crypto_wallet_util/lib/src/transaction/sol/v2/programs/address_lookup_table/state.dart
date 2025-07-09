import '../../crypto/pubkey.dart';

/// Address Lookup Table State
/// ------------------------------------------------------------------------------------------------

class AddressLookupTableState {
  const AddressLookupTableState({
    this.typeIndex = 1,
    required this.deactivationSlot,
    required this.lastExtendedSlot,
    required this.lastExtendedSlotStartIndex,
    required this.authority,
    required this.addresses,
  });

  final int typeIndex;
  final BigInt deactivationSlot;
  final BigInt lastExtendedSlot;
  final int lastExtendedSlotStartIndex;
  final Pubkey? authority;
  final List<Pubkey> addresses;
}

/// Address Lookup Table Account
/// ------------------------------------------------------------------------------------------------

class AddressLookupTableAccount {
  const AddressLookupTableAccount({
    required this.key,
    required this.state,
  });

  final Pubkey key;

  final AddressLookupTableState state;

  bool get isActive {
    final u64Max = BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16);
    return state.deactivationSlot == u64Max;
  }
}
