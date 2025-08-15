import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart' as auth_pb;

void main() {
  group('AccountI Interface Tests', () {
    test('should define required account interface properties', () {
      // Create a concrete implementation for testing
      final mockAccount = _MockAccountI();
      
      expect(mockAccount, isA<AccountI>());
      expect(mockAccount.address, isA<String>());
      expect(mockAccount.pubKey, isA<Any>());
      expect(mockAccount.accountNumber, isA<Int64>());
      expect(mockAccount.sequence, isA<Int64>());
    });

    test('should be implemented by BaseAccount', () {
      final baseAccountPb = auth_pb.BaseAccount(
        address: 'cosmos1test123456789',
        accountNumber: Int64(12345),
        sequence: Int64(67890),
      );
      final baseAccount = BaseAccount(baseAccountPb);
      
      expect(baseAccount, isA<AccountI>());
    });

    test('should be implemented by ModuleAccount', () {
      final baseAccountPb = auth_pb.BaseAccount(
        address: 'cosmos1module123456789',
        accountNumber: Int64(11111),
        sequence: Int64(22222),
      );
      final moduleAccountPb = auth_pb.ModuleAccount(
        baseAccount: baseAccountPb,
        name: 'test_module',
      );
      final moduleAccount = ModuleAccount(moduleAccountPb);
      
      expect(moduleAccount, isA<AccountI>());
    });
  });

  group('BaseAccount Tests', () {
    late auth_pb.BaseAccount mockBaseAccountPb;

    setUp(() {
      mockBaseAccountPb = auth_pb.BaseAccount(
        address: 'cosmos1baseaccount123456789',
        pubKey: Any()..typeUrl = 'type.googleapis.com/cosmos.crypto.secp256k1.PubKey',
        accountNumber: Int64(98765),
        sequence: Int64(54321),
      );
    });

    test('should create BaseAccount with proper account data', () {
      final account = BaseAccount(mockBaseAccountPb);
      
      expect(account.address, equals('cosmos1baseaccount123456789'));
      expect(account.pubKey, isA<Any>());
      expect(account.pubKey.typeUrl, equals('type.googleapis.com/cosmos.crypto.secp256k1.PubKey'));
      expect(account.accountNumber, equals(Int64(98765)));
      expect(account.sequence, equals(Int64(54321)));
    });

    test('should implement AccountI interface correctly', () {
      final account = BaseAccount(mockBaseAccountPb);
      
      expect(account, isA<AccountI>());
      expect(account.address, isA<String>());
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, isA<Int64>());
      expect(account.sequence, isA<Int64>());
    });

    test('should access underlying protobuf account properties', () {
      final account = BaseAccount(mockBaseAccountPb);
      
      expect(account.account, same(mockBaseAccountPb));
      expect(account.account.address, equals('cosmos1baseaccount123456789'));
      expect(account.account.accountNumber, equals(Int64(98765)));
      expect(account.account.sequence, equals(Int64(54321)));
    });

    test('should create BaseAccount from Any serialization', () {
      final serializedData = mockBaseAccountPb.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.auth.v1beta1.BaseAccount'
        ..value = serializedData;

      final deserializedAccount = BaseAccount.fromAny(any);

      expect(deserializedAccount.address, equals('cosmos1baseaccount123456789'));
      expect(deserializedAccount.accountNumber, equals(Int64(98765)));
      expect(deserializedAccount.sequence, equals(Int64(54321)));
    });

    test('should handle empty BaseAccount', () {
      final emptyBaseAccount = auth_pb.BaseAccount();
      final account = BaseAccount(emptyBaseAccount);
      
      expect(account.address, isEmpty);
      expect(account.accountNumber, equals(Int64.ZERO));
      expect(account.sequence, equals(Int64.ZERO));
      expect(account.pubKey, isA<Any>());
    });

    test('should handle BaseAccount with only address', () {
      final addressOnlyAccount = auth_pb.BaseAccount(
        address: 'cosmos1addressonly123456789',
      );
      final account = BaseAccount(addressOnlyAccount);
      
      expect(account.address, equals('cosmos1addressonly123456789'));
      expect(account.accountNumber, equals(Int64.ZERO));
      expect(account.sequence, equals(Int64.ZERO));
    });

    test('should handle BaseAccount with large numbers', () {
      final largeNumberAccount = auth_pb.BaseAccount(
        address: 'cosmos1largenumber123456789',
        accountNumber: Int64.MAX_VALUE,
        sequence: Int64.MAX_VALUE,
      );
      final account = BaseAccount(largeNumberAccount);
      
      expect(account.address, equals('cosmos1largenumber123456789'));
      expect(account.accountNumber, equals(Int64.MAX_VALUE));
      expect(account.sequence, equals(Int64.MAX_VALUE));
    });

    test('should handle BaseAccount with minimum numbers', () {
      final minNumberAccount = auth_pb.BaseAccount(
        address: 'cosmos1minnumber123456789',
        accountNumber: Int64.MIN_VALUE,
        sequence: Int64.MIN_VALUE,
      );
      final account = BaseAccount(minNumberAccount);
      
      expect(account.address, equals('cosmos1minnumber123456789'));
      expect(account.accountNumber, equals(Int64.MIN_VALUE));
      expect(account.sequence, equals(Int64.MIN_VALUE));
    });

    test('should handle BaseAccount with different pubKey types', () {
      final pubKeyTypes = [
        'type.googleapis.com/cosmos.crypto.secp256k1.PubKey',
        'type.googleapis.com/cosmos.crypto.ed25519.PubKey',
        'type.googleapis.com/cosmos.crypto.multisig.LegacyAminoPubKey',
        'type.googleapis.com/cosmos.crypto.secp256r1.PubKey',
      ];

      for (final pubKeyType in pubKeyTypes) {
        final testAccount = auth_pb.BaseAccount(
          address: 'cosmos1pubkeytest123456789',
          pubKey: Any()..typeUrl = pubKeyType,
          accountNumber: Int64(12345),
          sequence: Int64(67890),
        );
        final account = BaseAccount(testAccount);
        
        expect(account.pubKey.typeUrl, equals(pubKeyType));
        expect(account.address, equals('cosmos1pubkeytest123456789'));
      }
    });

    test('should handle serialization roundtrip correctly', () {
      final originalAccount = BaseAccount(mockBaseAccountPb);
      final serializedData = mockBaseAccountPb.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.auth.v1beta1.BaseAccount'
        ..value = serializedData;

      final deserializedAccount = BaseAccount.fromAny(any);

      expect(deserializedAccount.address, equals(originalAccount.address));
      expect(deserializedAccount.accountNumber, equals(originalAccount.accountNumber));
      expect(deserializedAccount.sequence, equals(originalAccount.sequence));
      expect(deserializedAccount.pubKey.typeUrl, equals(originalAccount.pubKey.typeUrl));
    });
  });

  group('ModuleAccount Tests', () {
    late auth_pb.ModuleAccount mockModuleAccountPb;
    late auth_pb.BaseAccount mockBaseAccountPb;

    setUp(() {
      mockBaseAccountPb = auth_pb.BaseAccount(
        address: 'cosmos1moduleaccount123456789',
        pubKey: Any()..typeUrl = 'type.googleapis.com/cosmos.crypto.secp256k1.PubKey',
        accountNumber: Int64(11111),
        sequence: Int64(22222),
      );

      mockModuleAccountPb = auth_pb.ModuleAccount(
        baseAccount: mockBaseAccountPb,
        name: 'staking',
        permissions: ['minter', 'burner'],
      );
    });

    test('should create ModuleAccount with proper account data', () {
      final account = ModuleAccount(mockModuleAccountPb);
      
      expect(account.address, equals('cosmos1moduleaccount123456789'));
      expect(account.pubKey, isA<Any>());
      expect(account.pubKey.typeUrl, equals('type.googleapis.com/cosmos.crypto.secp256k1.PubKey'));
      expect(account.accountNumber, equals(Int64(11111)));
      expect(account.sequence, equals(Int64(22222)));
    });

    test('should implement AccountI interface correctly', () {
      final account = ModuleAccount(mockModuleAccountPb);
      
      expect(account, isA<AccountI>());
      expect(account.address, isA<String>());
      expect(account.pubKey, isA<Any>());
      expect(account.accountNumber, isA<Int64>());
      expect(account.sequence, isA<Int64>());
    });

    test('should access module-specific properties', () {
      final account = ModuleAccount(mockModuleAccountPb);
      
      expect(account.account.name, equals('staking'));
      expect(account.account.permissions.length, equals(2));
      expect(account.account.permissions[0], equals('minter'));
      expect(account.account.permissions[1], equals('burner'));
    });

    test('should access base account properties through baseAccount', () {
      final account = ModuleAccount(mockModuleAccountPb);
      
      expect(account.account.baseAccount, same(mockBaseAccountPb));
      expect(account.account.baseAccount.address, equals('cosmos1moduleaccount123456789'));
      expect(account.account.baseAccount.accountNumber, equals(Int64(11111)));
      expect(account.account.baseAccount.sequence, equals(Int64(22222)));
    });

    test('should create ModuleAccount from Any serialization', () {
      final serializedData = mockModuleAccountPb.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.auth.v1beta1.ModuleAccount'
        ..value = serializedData;

      final deserializedAccount = ModuleAccount.fromAny(any);

      expect(deserializedAccount.address, equals('cosmos1moduleaccount123456789'));
      expect(deserializedAccount.accountNumber, equals(Int64(11111)));
      expect(deserializedAccount.sequence, equals(Int64(22222)));
    });

    test('should handle common module account types', () {
      final moduleTypes = [
        {'name': 'staking', 'permissions': ['minter', 'burner']},
        {'name': 'bonded_tokens_pool', 'permissions': ['burner', 'staking']},
        {'name': 'not_bonded_tokens_pool', 'permissions': ['burner', 'staking']},
        {'name': 'gov', 'permissions': ['burner']},
        {'name': 'distribution', 'permissions': <String>[]},
        {'name': 'mint', 'permissions': ['minter']},
        {'name': 'fee_collector', 'permissions': <String>[]},
      ];

      for (final moduleType in moduleTypes) {
        final baseAccount = auth_pb.BaseAccount(
          address: 'cosmos1${moduleType['name']}123456789',
          accountNumber: Int64(12345),
          sequence: Int64(67890),
        );
        
        final moduleAccount = auth_pb.ModuleAccount(
          baseAccount: baseAccount,
          name: moduleType['name']! as String,
          permissions: (moduleType['permissions']! as List).cast<String>(),
        );
        
        final account = ModuleAccount(moduleAccount);
        
        expect(account.account.name, equals(moduleType['name']));
        expect(account.account.permissions, equals(moduleType['permissions']));
        expect(account.address, equals('cosmos1${moduleType['name']}123456789'));
      }
    });

    test('should handle ModuleAccount with empty base account', () {
      final emptyBaseAccount = auth_pb.BaseAccount();
      final moduleAccount = auth_pb.ModuleAccount(
        baseAccount: emptyBaseAccount,
        name: 'empty_module',
        permissions: [],
      );
      
      final account = ModuleAccount(moduleAccount);
      
      expect(account.address, isEmpty);
      expect(account.accountNumber, equals(Int64.ZERO));
      expect(account.sequence, equals(Int64.ZERO));
      expect(account.account.name, equals('empty_module'));
      expect(account.account.permissions.isEmpty, isTrue);
    });

    test('should handle ModuleAccount with no permissions', () {
      final moduleAccount = auth_pb.ModuleAccount(
        baseAccount: mockBaseAccountPb,
        name: 'no_permissions_module',
        permissions: [],
      );
      
      final account = ModuleAccount(moduleAccount);
      
      expect(account.account.name, equals('no_permissions_module'));
      expect(account.account.permissions.isEmpty, isTrue);
      expect(account.address, equals('cosmos1moduleaccount123456789'));
    });

    test('should handle ModuleAccount with many permissions', () {
      final manyPermissions = [
        'minter', 'burner', 'staking', 'governance', 'distribution',
        'slashing', 'evidence', 'upgrade', 'params', 'crisis',
      ];
      
      final moduleAccount = auth_pb.ModuleAccount(
        baseAccount: mockBaseAccountPb,
        name: 'many_permissions_module',
        permissions: manyPermissions,
      );
      
      final account = ModuleAccount(moduleAccount);
      
      expect(account.account.name, equals('many_permissions_module'));
      expect(account.account.permissions.length, equals(10));
      expect(account.account.permissions, containsAll(manyPermissions));
    });

    test('should handle serialization roundtrip correctly', () {
      final originalAccount = ModuleAccount(mockModuleAccountPb);
      final serializedData = mockModuleAccountPb.writeToBuffer();
      final any = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.auth.v1beta1.ModuleAccount'
        ..value = serializedData;

      final deserializedAccount = ModuleAccount.fromAny(any);

      expect(deserializedAccount.address, equals(originalAccount.address));
      expect(deserializedAccount.accountNumber, equals(originalAccount.accountNumber));
      expect(deserializedAccount.sequence, equals(originalAccount.sequence));
      expect(deserializedAccount.account.name, equals(originalAccount.account.name));
      expect(deserializedAccount.account.permissions, equals(originalAccount.account.permissions));
    });
  });

  group('Account Integration Tests', () {
    test('should handle both BaseAccount and ModuleAccount as AccountI', () {
      final baseAccountPb = auth_pb.BaseAccount(
        address: 'cosmos1base123456789',
        accountNumber: Int64(11111),
        sequence: Int64(22222),
      );

      final moduleAccountPb = auth_pb.ModuleAccount(
        baseAccount: auth_pb.BaseAccount(
          address: 'cosmos1module123456789',
          accountNumber: Int64(33333),
          sequence: Int64(44444),
        ),
        name: 'test_module',
        permissions: ['minter'],
      );

      final accounts = <AccountI>[
        BaseAccount(baseAccountPb),
        ModuleAccount(moduleAccountPb),
      ];

      // Both should implement AccountI interface
      for (final account in accounts) {
        expect(account, isA<AccountI>());
        expect(account.address, isA<String>());
        expect(account.pubKey, isA<Any>());
        expect(account.accountNumber, isA<Int64>());
        expect(account.sequence, isA<Int64>());
      }

      // Verify specific properties
      expect(accounts[0].address, equals('cosmos1base123456789'));
      expect(accounts[0].accountNumber, equals(Int64(11111)));
      
      expect(accounts[1].address, equals('cosmos1module123456789'));
      expect(accounts[1].accountNumber, equals(Int64(33333)));
    });

    test('should handle different account number ranges', () {
      final testCases = [
        {'accountNumber': Int64.ZERO, 'sequence': Int64.ZERO},
        {'accountNumber': Int64.ONE, 'sequence': Int64.ONE},
        {'accountNumber': Int64(1000000), 'sequence': Int64(2000000)},
        {'accountNumber': Int64.MAX_VALUE, 'sequence': Int64.MAX_VALUE},
      ];

      for (int i = 0; i < testCases.length; i++) {
        final testCase = testCases[i];
        final baseAccountPb = auth_pb.BaseAccount(
          address: 'cosmos1test$i',
          accountNumber: testCase['accountNumber']!,
          sequence: testCase['sequence']!,
        );
        
        final account = BaseAccount(baseAccountPb);
        
        expect(account.accountNumber, equals(testCase['accountNumber']));
        expect(account.sequence, equals(testCase['sequence']));
      }
    });

    test('should handle serialization consistency across account types', () {
      // Test BaseAccount serialization
      final baseAccountPb = auth_pb.BaseAccount(
        address: 'cosmos1serialization123456789',
        accountNumber: Int64(98765),
        sequence: Int64(54321),
      );
      
      final baseSerializedData = baseAccountPb.writeToBuffer();
      final baseAny = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.auth.v1beta1.BaseAccount'
        ..value = baseSerializedData;
      
      final deserializedBase = BaseAccount.fromAny(baseAny);
      
      // Test ModuleAccount serialization
      final moduleAccountPb = auth_pb.ModuleAccount(
        baseAccount: baseAccountPb,
        name: 'serialization_module',
        permissions: ['test_permission'],
      );
      
      final moduleSerializedData = moduleAccountPb.writeToBuffer();
      final moduleAny = Any()
        ..typeUrl = 'type.googleapis.com/cosmos.auth.v1beta1.ModuleAccount'
        ..value = moduleSerializedData;
      
      final deserializedModule = ModuleAccount.fromAny(moduleAny);
      
      // Both should have same base account properties
      expect(deserializedBase.address, equals(deserializedModule.address));
      expect(deserializedBase.accountNumber, equals(deserializedModule.accountNumber));
      expect(deserializedBase.sequence, equals(deserializedModule.sequence));
    });

    test('should handle edge cases with empty and null data', () {
      // Test with minimal data
      final minimalBase = auth_pb.BaseAccount();
      final minimalModule = auth_pb.ModuleAccount(
        baseAccount: minimalBase,
        name: '',
        permissions: [],
      );

      final baseAccount = BaseAccount(minimalBase);
      final moduleAccount = ModuleAccount(minimalModule);

      expect(baseAccount, isA<AccountI>());
      expect(moduleAccount, isA<AccountI>());
      
      expect(baseAccount.address, isEmpty);
      expect(moduleAccount.address, isEmpty);
      
      expect(baseAccount.accountNumber, equals(Int64.ZERO));
      expect(moduleAccount.accountNumber, equals(Int64.ZERO));
    });

    test('should validate account type consistency', () {
      final baseAccountPb = auth_pb.BaseAccount(
        address: 'cosmos1consistency123456789',
        accountNumber: Int64(12345),
        sequence: Int64(67890),
      );

      final moduleAccountPb = auth_pb.ModuleAccount(
        baseAccount: baseAccountPb,
        name: 'consistency_module',
      );

      final baseAccount = BaseAccount(baseAccountPb);
      final moduleAccount = ModuleAccount(moduleAccountPb);

      // Type checks
      expect(baseAccount, isA<BaseAccount>());
      expect(baseAccount, isA<AccountI>());
      expect(baseAccount, isNot(isA<ModuleAccount>()));

      expect(moduleAccount, isA<ModuleAccount>());
      expect(moduleAccount, isA<AccountI>());
      expect(moduleAccount, isNot(isA<BaseAccount>()));
    });

    test('should handle realistic Cosmos addresses', () {
      final cosmosAddresses = [
        'cosmos1fl48vsnmsdzcv85q5d2q4z5ajdha8yu34mf0eh',
        'cosmos1jv65s3grqf6v6jl3dp4t6c9t9rk99cd88lyufl',
        'cosmos15urq2dtp9qce4fyc85m6upwm9xul3049e02707',
        'cosmos1x5wgh6vwye60wv3dtshs9dmqggwfx2ldnqvev6',
        'cosmos1lktjhnzkpkz3ehrg8psvmwhafg56kfss3q3t8m',
      ];

      for (int i = 0; i < cosmosAddresses.length; i++) {
        final address = cosmosAddresses[i];
        final baseAccountPb = auth_pb.BaseAccount(
          address: address,
          accountNumber: Int64(i + 1000),
          sequence: Int64(i + 2000),
        );
        
        final account = BaseAccount(baseAccountPb);
        
        expect(account.address, equals(address));
        expect(account.address.startsWith('cosmos1'), isTrue);
        expect(account.address.length, equals(45)); // Standard cosmos address length
      }
    });
  });
}

// Mock implementation for testing AccountI interface
class _MockAccountI implements AccountI {
  @override
  String get address => 'cosmos1mock123456789';

  @override
  Any get pubKey => Any();

  @override
  Int64 get accountNumber => Int64(12345);

  @override
  Int64 get sequence => Int64(67890);
} 