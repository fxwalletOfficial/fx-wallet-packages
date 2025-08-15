import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/vesting/v1beta1/vesting.pb.dart' as vesting_pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart' as auth_pb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/v1beta1/coin.pb.dart' as coin_pb;

void main() {
  group('BaseVestingAccount Tests', () {
    late vesting_pb.BaseVestingAccount mockVestingAccount;
    late auth_pb.BaseAccount mockBaseAccount;

    setUp(() {
      mockBaseAccount = auth_pb.BaseAccount(
        address: 'cosmos1test123456789',
        pubKey: Any(),
        accountNumber: Int64(12345),
        sequence: Int64(67890),
      );

      mockVestingAccount = vesting_pb.BaseVestingAccount(
        baseAccount: mockBaseAccount,
        originalVesting: [
          coin_pb.CosmosCoin(denom: 'atom', amount: '1000000'),
          coin_pb.CosmosCoin(denom: 'osmo', amount: '500000'),
        ],
        delegatedFree: [
          coin_pb.CosmosCoin(denom: 'atom', amount: '100000'),
        ],
        delegatedVesting: [
          coin_pb.CosmosCoin(denom: 'atom', amount: '200000'),
        ],
        endTime: Int64(1234567890),
      );
    });

    test('should create BaseVestingAccount with proper account data', () {
      final account = BaseVestingAccount(mockVestingAccount);

      expect(account.address, equals('cosmos1test123456789'));
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, equals(Int64(12345)));
      expect(account.sequence, equals(Int64(67890)));
    });

    test('should implement AccountI interface correctly', () {
      final account = BaseVestingAccount(mockVestingAccount);

      expect(account, isA<AccountI>());
      expect(account.address, isA<String>());
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, isA<Int64>());
      expect(account.sequence, isA<Int64>());
    });

    test('should access underlying protobuf account properties', () {
      final account = BaseVestingAccount(mockVestingAccount);

      expect(account.account.originalVesting.length, equals(2));
      expect(account.account.originalVesting[0].denom, equals('atom'));
      expect(account.account.originalVesting[0].amount, equals('1000000'));
      expect(account.account.originalVesting[1].denom, equals('osmo'));
      expect(account.account.originalVesting[1].amount, equals('500000'));
      
      expect(account.account.delegatedFree.length, equals(1));
      expect(account.account.delegatedFree[0].amount, equals('100000'));
      
      expect(account.account.delegatedVesting.length, equals(1));
      expect(account.account.delegatedVesting[0].amount, equals('200000'));
      
      expect(account.account.endTime, equals(Int64(1234567890)));
    });

    test('should create BaseVestingAccount from Any serialization', () {
      final serializedData = mockVestingAccount.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.vesting.v1beta1.BaseVestingAccount'
        ..value = serializedData;

      final deserializedAccount = BaseVestingAccount.fromAny(any);

      expect(deserializedAccount.address, equals('cosmos1test123456789'));
      expect(deserializedAccount.accountNumber, equals(Int64(12345)));
      expect(deserializedAccount.sequence, equals(Int64(67890)));
    });

    test('should handle empty base account', () {
      final emptyBaseAccount = auth_pb.BaseAccount();
      final emptyVestingAccount = vesting_pb.BaseVestingAccount(
        baseAccount: emptyBaseAccount,
      );
      
      final account = BaseVestingAccount(emptyVestingAccount);
      
      expect(account.address, isEmpty);
      expect(account.accountNumber, equals(Int64.ZERO));
      expect(account.sequence, equals(Int64.ZERO));
    });

    test('should handle vesting account without coins', () {
      final vestingAccount = vesting_pb.BaseVestingAccount(
        baseAccount: mockBaseAccount,
        endTime: Int64(1234567890),
      );
      
      final account = BaseVestingAccount(vestingAccount);
      
      expect(account.account.originalVesting.isEmpty, isTrue);
      expect(account.account.delegatedFree.isEmpty, isTrue);
      expect(account.account.delegatedVesting.isEmpty, isTrue);
      expect(account.account.endTime, equals(Int64(1234567890)));
    });
  });

  group('DelayedVestingAccount Tests', () {
    late vesting_pb.DelayedVestingAccount mockDelayedVestingAccount;
    late vesting_pb.BaseVestingAccount mockBaseVestingAccount;
    late auth_pb.BaseAccount mockBaseAccount;

    setUp(() {
      mockBaseAccount = auth_pb.BaseAccount(
        address: 'cosmos1delayed123456789',
        pubKey: Any(),
        accountNumber: Int64(54321),
        sequence: Int64(98765),
      );

      mockBaseVestingAccount = vesting_pb.BaseVestingAccount(
        baseAccount: mockBaseAccount,
        originalVesting: [
          coin_pb.CosmosCoin(denom: 'atom', amount: '2000000'),
        ],
        endTime: Int64(1640995200), // 2022-01-01
      );

      mockDelayedVestingAccount = vesting_pb.DelayedVestingAccount(
        baseVestingAccount: mockBaseVestingAccount,
      );
    });

    test('should create DelayedVestingAccount with proper account data', () {
      final account = DelayedVestingAccount(mockDelayedVestingAccount);

      expect(account.address, equals('cosmos1delayed123456789'));
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, equals(Int64(54321)));
      expect(account.sequence, equals(Int64(98765)));
    });

    test('should implement AccountI interface correctly', () {
      final account = DelayedVestingAccount(mockDelayedVestingAccount);

      expect(account, isA<AccountI>());
      expect(account.address, isA<String>());
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, isA<Int64>());
      expect(account.sequence, isA<Int64>());
    });

    test('should access base vesting account properties', () {
      final account = DelayedVestingAccount(mockDelayedVestingAccount);

      expect(account.account.baseVestingAccount.originalVesting.length, equals(1));
      expect(account.account.baseVestingAccount.originalVesting[0].denom, equals('atom'));
      expect(account.account.baseVestingAccount.originalVesting[0].amount, equals('2000000'));
      expect(account.account.baseVestingAccount.endTime, equals(Int64(1640995200)));
    });

    test('should create DelayedVestingAccount from Any serialization', () {
      final serializedData = mockDelayedVestingAccount.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.vesting.v1beta1.DelayedVestingAccount'
        ..value = serializedData;

      final deserializedAccount = DelayedVestingAccount.fromAny(any);

      expect(deserializedAccount.address, equals('cosmos1delayed123456789'));
      expect(deserializedAccount.accountNumber, equals(Int64(54321)));
      expect(deserializedAccount.sequence, equals(Int64(98765)));
    });

    test('should handle delayed vesting account with multiple coins', () {
      final multiCoinBaseVesting = vesting_pb.BaseVestingAccount(
        baseAccount: mockBaseAccount,
        originalVesting: [
          coin_pb.CosmosCoin(denom: 'atom', amount: '1000000'),
          coin_pb.CosmosCoin(denom: 'osmo', amount: '2000000'),
          coin_pb.CosmosCoin(denom: 'juno', amount: '3000000'),
        ],
        delegatedFree: [
          coin_pb.CosmosCoin(denom: 'atom', amount: '100000'),
        ],
        endTime: Int64(1672531200), // 2023-01-01
      );

      final delayedAccount = vesting_pb.DelayedVestingAccount(
        baseVestingAccount: multiCoinBaseVesting,
      );

      final account = DelayedVestingAccount(delayedAccount);

      expect(account.account.baseVestingAccount.originalVesting.length, equals(3));
      expect(account.account.baseVestingAccount.delegatedFree.length, equals(1));
      expect(account.account.baseVestingAccount.endTime, equals(Int64(1672531200)));
    });
  });

  group('ContinuousVestingAccount Tests', () {
    late vesting_pb.ContinuousVestingAccount mockContinuousVestingAccount;
    late vesting_pb.BaseVestingAccount mockBaseVestingAccount;
    late auth_pb.BaseAccount mockBaseAccount;

    setUp(() {
      mockBaseAccount = auth_pb.BaseAccount(
        address: 'cosmos1continuous123456789',
        pubKey: Any(),
        accountNumber: Int64(11111),
        sequence: Int64(22222),
      );

      mockBaseVestingAccount = vesting_pb.BaseVestingAccount(
        baseAccount: mockBaseAccount,
        originalVesting: [
          coin_pb.CosmosCoin(denom: 'atom', amount: '5000000'),
        ],
        endTime: Int64(1704067200), // 2024-01-01
      );

      mockContinuousVestingAccount = vesting_pb.ContinuousVestingAccount(
        baseVestingAccount: mockBaseVestingAccount,
        startTime: Int64(1640995200), // 2022-01-01
      );
    });

    test('should create ContinuousVestingAccount with proper account data', () {
      final account = ContinuousVestingAccount(mockContinuousVestingAccount);

      expect(account.address, equals('cosmos1continuous123456789'));
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, equals(Int64(11111)));
      expect(account.sequence, equals(Int64(22222)));
    });

    test('should implement AccountI interface correctly', () {
      final account = ContinuousVestingAccount(mockContinuousVestingAccount);

      expect(account, isA<AccountI>());
      expect(account.address, isA<String>());
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, isA<Int64>());
      expect(account.sequence, isA<Int64>());
    });

    test('should access continuous vesting specific properties', () {
      final account = ContinuousVestingAccount(mockContinuousVestingAccount);

      expect(account.account.startTime, equals(Int64(1640995200)));
      expect(account.account.baseVestingAccount.endTime, equals(Int64(1704067200)));
      expect(account.account.baseVestingAccount.originalVesting.length, equals(1));
      expect(account.account.baseVestingAccount.originalVesting[0].amount, equals('5000000'));
    });

    test('should create ContinuousVestingAccount from Any serialization', () {
      final serializedData = mockContinuousVestingAccount.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.vesting.v1beta1.ContinuousVestingAccount'
        ..value = serializedData;

      final deserializedAccount = ContinuousVestingAccount.fromAny(any);

      expect(deserializedAccount.address, equals('cosmos1continuous123456789'));
      expect(deserializedAccount.accountNumber, equals(Int64(11111)));
      expect(deserializedAccount.sequence, equals(Int64(22222)));
    });

    test('should handle continuous vesting with zero start time', () {
      final continuousAccount = vesting_pb.ContinuousVestingAccount(
        baseVestingAccount: mockBaseVestingAccount,
        startTime: Int64.ZERO,
      );

      final account = ContinuousVestingAccount(continuousAccount);

      expect(account.account.startTime, equals(Int64.ZERO));
      expect(account.account.baseVestingAccount.endTime, equals(Int64(1704067200)));
    });

    test('should handle vesting period calculations', () {
      final startTime = Int64(1640995200); // 2022-01-01
      final endTime = Int64(1704067200);   // 2024-01-01
      
      final continuousAccount = vesting_pb.ContinuousVestingAccount(
        baseVestingAccount: vesting_pb.BaseVestingAccount(
          baseAccount: mockBaseAccount,
          originalVesting: [
            coin_pb.CosmosCoin(denom: 'atom', amount: '10000000'),
          ],
          endTime: endTime,
        ),
        startTime: startTime,
      );

      final account = ContinuousVestingAccount(continuousAccount);

      // Verify vesting period setup
      final vestingPeriod = account.account.baseVestingAccount.endTime.toInt() - 
                           account.account.startTime.toInt();
      expect(vestingPeriod, equals(63072000)); // 2 years in seconds
    });
  });

  group('PeriodicVestingAccount Tests', () {
    late vesting_pb.PeriodicVestingAccount mockPeriodicVestingAccount;
    late vesting_pb.BaseVestingAccount mockBaseVestingAccount;
    late auth_pb.BaseAccount mockBaseAccount;

    setUp(() {
      mockBaseAccount = auth_pb.BaseAccount(
        address: 'cosmos1periodic123456789',
        pubKey: Any(),
        accountNumber: Int64(33333),
        sequence: Int64(44444),
      );

      mockBaseVestingAccount = vesting_pb.BaseVestingAccount(
        baseAccount: mockBaseAccount,
        originalVesting: [
          coin_pb.CosmosCoin(denom: 'atom', amount: '12000000'),
        ],
        endTime: Int64(1735689600), // 2025-01-01
      );

      mockPeriodicVestingAccount = vesting_pb.PeriodicVestingAccount(
        baseVestingAccount: mockBaseVestingAccount,
        startTime: Int64(1640995200), // 2022-01-01
        vestingPeriods: [
          vesting_pb.Period(
            length: Int64(31536000), // 1 year
            amount: [coin_pb.CosmosCoin(denom: 'atom', amount: '4000000')],
          ),
          vesting_pb.Period(
            length: Int64(31536000), // 1 year
            amount: [coin_pb.CosmosCoin(denom: 'atom', amount: '4000000')],
          ),
          vesting_pb.Period(
            length: Int64(31536000), // 1 year
            amount: [coin_pb.CosmosCoin(denom: 'atom', amount: '4000000')],
          ),
        ],
      );
    });

    test('should create PeriodicVestingAccount with proper account data', () {
      final account = PeriodicVestingAccount(mockPeriodicVestingAccount);

      expect(account.address, equals('cosmos1periodic123456789'));
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, equals(Int64(33333)));
      expect(account.sequence, equals(Int64(44444)));
    });

    test('should implement AccountI interface correctly', () {
      final account = PeriodicVestingAccount(mockPeriodicVestingAccount);

      expect(account, isA<AccountI>());
      expect(account.address, isA<String>());
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, isA<Int64>());
      expect(account.sequence, isA<Int64>());
    });

    test('should access periodic vesting specific properties', () {
      final account = PeriodicVestingAccount(mockPeriodicVestingAccount);

      expect(account.account.startTime, equals(Int64(1640995200)));
      expect(account.account.vestingPeriods.length, equals(3));
      
      // Check first period
      expect(account.account.vestingPeriods[0].length, equals(Int64(31536000)));
      expect(account.account.vestingPeriods[0].amount.length, equals(1));
      expect(account.account.vestingPeriods[0].amount[0].denom, equals('atom'));
      expect(account.account.vestingPeriods[0].amount[0].amount, equals('4000000'));
      
      // Check that all periods have the same structure
      for (int i = 0; i < 3; i++) {
        expect(account.account.vestingPeriods[i].length, equals(Int64(31536000)));
        expect(account.account.vestingPeriods[i].amount[0].amount, equals('4000000'));
      }
    });

    test('should create PeriodicVestingAccount from Any serialization', () {
      final serializedData = mockPeriodicVestingAccount.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.vesting.v1beta1.PeriodicVestingAccount'
        ..value = serializedData;

      final deserializedAccount = PeriodicVestingAccount.fromAny(any);

      expect(deserializedAccount.address, equals('cosmos1periodic123456789'));
      expect(deserializedAccount.accountNumber, equals(Int64(33333)));
      expect(deserializedAccount.sequence, equals(Int64(44444)));
    });

    test('should handle periodic vesting with multiple coin types', () {
      final multiCoinPeriods = [
        vesting_pb.Period(
          length: Int64(15768000), // 6 months
          amount: [
            coin_pb.CosmosCoin(denom: 'atom', amount: '1000000'),
            coin_pb.CosmosCoin(denom: 'osmo', amount: '2000000'),
          ],
        ),
        vesting_pb.Period(
          length: Int64(15768000), // 6 months
          amount: [
            coin_pb.CosmosCoin(denom: 'juno', amount: '3000000'),
          ],
        ),
      ];

      final periodicAccount = vesting_pb.PeriodicVestingAccount(
        baseVestingAccount: mockBaseVestingAccount,
        startTime: Int64(1640995200),
        vestingPeriods: multiCoinPeriods,
      );

      final account = PeriodicVestingAccount(periodicAccount);

      expect(account.account.vestingPeriods.length, equals(2));
      expect(account.account.vestingPeriods[0].amount.length, equals(2));
      expect(account.account.vestingPeriods[0].amount[0].denom, equals('atom'));
      expect(account.account.vestingPeriods[0].amount[1].denom, equals('osmo'));
      expect(account.account.vestingPeriods[1].amount.length, equals(1));
      expect(account.account.vestingPeriods[1].amount[0].denom, equals('juno'));
    });

    test('should handle empty vesting periods', () {
      final emptyPeriodicAccount = vesting_pb.PeriodicVestingAccount(
        baseVestingAccount: mockBaseVestingAccount,
        startTime: Int64(1640995200),
        vestingPeriods: [],
      );

      final account = PeriodicVestingAccount(emptyPeriodicAccount);

      expect(account.account.vestingPeriods.isEmpty, isTrue);
      expect(account.account.startTime, equals(Int64(1640995200)));
    });

    test('should calculate total vesting amount from periods', () {
      final account = PeriodicVestingAccount(mockPeriodicVestingAccount);
      
      var totalAmount = 0;
      for (final period in account.account.vestingPeriods) {
        for (final coin in period.amount) {
          if (coin.denom == 'atom') {
            totalAmount += int.parse(coin.amount);
          }
        }
      }
      
      expect(totalAmount, equals(12000000)); // 3 periods * 4000000 each
    });
  });

  group('Vesting Account Integration Tests', () {
    test('should handle different vesting account types consistently', () {
      final baseAccount = auth_pb.BaseAccount(
        address: 'cosmos1integration123456789',
        pubKey: Any(),
        accountNumber: Int64(99999),
        sequence: Int64(88888),
      );

      // Test that all vesting account types access the same base account info
      final baseVesting = vesting_pb.BaseVestingAccount(
        baseAccount: baseAccount,
        originalVesting: [coin_pb.CosmosCoin(denom: 'atom', amount: '1000000')],
        endTime: Int64(1672531200),
      );

      final delayed = vesting_pb.DelayedVestingAccount(baseVestingAccount: baseVesting);
      final continuous = vesting_pb.ContinuousVestingAccount(
        baseVestingAccount: baseVesting,
        startTime: Int64(1640995200),
      );
      final periodic = vesting_pb.PeriodicVestingAccount(
        baseVestingAccount: baseVesting,
        startTime: Int64(1640995200),
        vestingPeriods: [
          vesting_pb.Period(
            length: Int64(31536000),
            amount: [coin_pb.CosmosCoin(denom: 'atom', amount: '1000000')],
          ),
        ],
      );

      final baseVestingAccount = BaseVestingAccount(baseVesting);
      final delayedVestingAccount = DelayedVestingAccount(delayed);
      final continuousVestingAccount = ContinuousVestingAccount(continuous);
      final periodicVestingAccount = PeriodicVestingAccount(periodic);

      final accounts = [
        baseVestingAccount,
        delayedVestingAccount,
        continuousVestingAccount,
        periodicVestingAccount,
      ];

      // All accounts should have the same basic account properties
      for (final account in accounts) {
        expect(account.address, equals('cosmos1integration123456789'));
        expect(account.accountNumber, equals(Int64(99999)));
        expect(account.sequence, equals(Int64(88888)));
      }
    });

    test('should handle serialization and deserialization roundtrip', () {
      final baseAccount = auth_pb.BaseAccount(
        address: 'cosmos1roundtrip123456789',
        pubKey: Any(),
        accountNumber: Int64(77777),
        sequence: Int64(66666),
      );

      final originalVesting = [
        coin_pb.CosmosCoin(denom: 'atom', amount: '5000000'),
        coin_pb.CosmosCoin(denom: 'osmo', amount: '3000000'),
      ];

      // Test continuous vesting account roundtrip
      final originalContinuous = vesting_pb.ContinuousVestingAccount(
        baseVestingAccount: vesting_pb.BaseVestingAccount(
          baseAccount: baseAccount,
          originalVesting: originalVesting,
          endTime: Int64(1735689600),
        ),
        startTime: Int64(1640995200),
      );

      final serializedData = originalContinuous.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.vesting.v1beta1.ContinuousVestingAccount'
        ..value = serializedData;

      final deserializedAccount = ContinuousVestingAccount.fromAny(any);

      expect(deserializedAccount.address, equals('cosmos1roundtrip123456789'));
      expect(deserializedAccount.accountNumber, equals(Int64(77777)));
      expect(deserializedAccount.sequence, equals(Int64(66666)));
      expect(deserializedAccount.account.startTime, equals(Int64(1640995200)));
      expect(deserializedAccount.account.baseVestingAccount.originalVesting.length, equals(2));
    });

    test('should handle edge cases with null or empty data', () {
      // Create minimal accounts
      final minimalBaseAccount = auth_pb.BaseAccount();
      final minimalBaseVesting = vesting_pb.BaseVestingAccount(
        baseAccount: minimalBaseAccount,
      );

      final accounts = [
        BaseVestingAccount(minimalBaseVesting),
        DelayedVestingAccount(vesting_pb.DelayedVestingAccount(
          baseVestingAccount: minimalBaseVesting,
        )),
        ContinuousVestingAccount(vesting_pb.ContinuousVestingAccount(
          baseVestingAccount: minimalBaseVesting,
          startTime: Int64.ZERO,
        )),
        PeriodicVestingAccount(vesting_pb.PeriodicVestingAccount(
          baseVestingAccount: minimalBaseVesting,
          startTime: Int64.ZERO,
          vestingPeriods: [],
        )),
      ];

      for (final account in accounts) {
        expect(account.address, isEmpty);
        expect(account.accountNumber, equals(Int64.ZERO));
        expect(account.sequence, equals(Int64.ZERO));
        expect(account, isA<AccountI>());
      }
    });

    test('should validate account type consistency', () {
      final baseAccount = auth_pb.BaseAccount(
        address: 'cosmos1validation123456789',
        accountNumber: Int64(55555),
        sequence: Int64(11111),
      );

      final baseVesting = vesting_pb.BaseVestingAccount(baseAccount: baseAccount);

      final accounts = <AccountI>[
        BaseVestingAccount(baseVesting),
        DelayedVestingAccount(vesting_pb.DelayedVestingAccount(baseVestingAccount: baseVesting)),
        ContinuousVestingAccount(vesting_pb.ContinuousVestingAccount(baseVestingAccount: baseVesting, startTime: Int64.ZERO)),
        PeriodicVestingAccount(vesting_pb.PeriodicVestingAccount(baseVestingAccount: baseVesting, startTime: Int64.ZERO, vestingPeriods: [])),
      ];

      // Verify all implement AccountI interface
      for (final account in accounts) {
        expect(account, isA<AccountI>());
        expect(account.address, isA<String>());
        expect(account.pubKey, isA<Any>());
        expect(account.accountNumber, isA<Int64>());
        expect(account.sequence, isA<Int64>());
      }

      // Verify specific types
      expect(accounts[0], isA<BaseVestingAccount>());
      expect(accounts[1], isA<DelayedVestingAccount>());
      expect(accounts[2], isA<ContinuousVestingAccount>());
      expect(accounts[3], isA<PeriodicVestingAccount>());
    });
  });
} 