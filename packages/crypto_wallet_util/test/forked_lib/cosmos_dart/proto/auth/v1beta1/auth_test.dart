import 'dart:convert';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart' as authpb;
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/genesis.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as pb;

void main() {
	group('proto cosmos.auth.v1beta1 auth', () {
		test('BaseAccount roundtrip', () {
			final base = BaseAccount(
				address: 'cosmos1xyz',
				pubKey: Any(typeUrl: 'type', value: [1,2,3]),
				accountNumber: Int64(9),
				sequence: Int64(7),
			);
			final bytes = base.writeToBuffer();
			final decoded = BaseAccount.fromBuffer(bytes);
			expect(decoded.address, 'cosmos1xyz');
			expect(decoded.pubKey.typeUrl, 'type');
			expect(decoded.accountNumber.toInt(), 9);
			expect(decoded.sequence.toInt(), 7);
		});

		test('ModuleAccount roundtrip', () {
			final mod = ModuleAccount(
				baseAccount: BaseAccount(address: 'cosmos1abc'),
				name: 'bank',
				permissions: ['minter','burner'],
			);
			final bytes = mod.writeToBuffer();
			final decoded = ModuleAccount.fromBuffer(bytes);
			expect(decoded.baseAccount.address, 'cosmos1abc');
			expect(decoded.name, 'bank');
			expect(decoded.permissions, ['minter','burner']);
		});

		test('BaseAccount methods: has/clear/ensure/copyWith/json/errors', () {
			final b = BaseAccount(
				address: 'cosmos1addr',
				pubKey: Any(typeUrl: 't', value: [1,2]),
				accountNumber: Int64(0),
				sequence: Int64(0),
			);
			expect(b.hasAddress(), isTrue);
			expect(b.hasPubKey(), isTrue);
			expect(b.hasAccountNumber(), isTrue);
			expect(b.hasSequence(), isTrue);

			b.clearAddress();
			b.clearPubKey();
			b.clearAccountNumber();
			b.clearSequence();
			expect(b.hasAddress(), isFalse);
			expect(b.hasPubKey(), isFalse);
			expect(b.hasAccountNumber(), isFalse);
			expect(b.hasSequence(), isFalse);

			final ensured = b.ensurePubKey();
			expect(ensured, isA<Any>());

			final copied = b.copyWith((m) {
				m.address = '';
				m.accountNumber = Int64(9223372036854775807);
				m.sequence = Int64(0);
				m.pubKey = Any(typeUrl: 'p');
			});
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
			final decoded = BaseAccount.fromJson(jsonStr);
			expect(decoded.address, '');
			expect(decoded.accountNumber.toInt(), 9223372036854775807);
			expect(decoded.sequence.toInt(), 0);
			expect(decoded.pubKey.typeUrl.isNotEmpty, isTrue);

			final bz = copied.writeToBuffer();
			final parsed = BaseAccount.fromBuffer(bz);
			expect(parsed.accountNumber.toInt(), 9223372036854775807);
			expect(() => BaseAccount.fromBuffer([0xFF, 0x00, 0xAA]), throwsA(isA<pb.InvalidProtocolBufferException>()));
			expect(() => BaseAccount.fromJson('not-json'), throwsA(isA<FormatException>()));
		});

		test('BaseAccount getDefault/createEmptyInstance/createRepeated', () {
			final def = BaseAccount.getDefault();
			expect(def, isA<BaseAccount>());
			final empty = BaseAccount().createEmptyInstance();
			expect(empty, isA<BaseAccount>());
			final list = BaseAccount.createRepeated();
			expect(list, isA<pb.PbList<BaseAccount>>());
		});

		test('Params roundtrip, has/clear, copyWith and fromJson', () {
			final p = authpb.Params(
				maxMemoCharacters: Int64(256),
				txSigLimit: Int64(7),
				txSizeCostPerByte: Int64(5),
				sigVerifyCostEd25519: Int64(999),
				sigVerifyCostSecp256k1: Int64(888),
			);
			expect(p.hasMaxMemoCharacters(), isTrue);
			expect(p.hasTxSigLimit(), isTrue);
			expect(p.hasTxSizeCostPerByte(), isTrue);
			expect(p.hasSigVerifyCostEd25519(), isTrue);
			expect(p.hasSigVerifyCostSecp256k1(), isTrue);
			final p2 = p.copyWith((pp) {
				pp.maxMemoCharacters = Int64(1);
				pp.txSigLimit = Int64(2);
				pp.txSizeCostPerByte = Int64(3);
				pp.sigVerifyCostEd25519 = Int64(4);
				pp.sigVerifyCostSecp256k1 = Int64(5);
			});
			final jsonStr = jsonEncode(p2.writeToJsonMap());
			expect(jsonStr.contains('1'), isTrue);
			final parsed = authpb.Params.fromJson(jsonStr);
			expect(parsed.maxMemoCharacters.toInt(), 1);
			expect(parsed.txSigLimit.toInt(), 2);
			expect(parsed.txSizeCostPerByte.toInt(), 3);
			expect(parsed.sigVerifyCostEd25519.toInt(), 4);
			expect(parsed.sigVerifyCostSecp256k1.toInt(), 5);
			p.clearMaxMemoCharacters();
			p.clearTxSigLimit();
			p.clearTxSizeCostPerByte();
			p.clearSigVerifyCostEd25519();
			p.clearSigVerifyCostSecp256k1();
			expect(p.hasMaxMemoCharacters(), isFalse);
			expect(p.hasTxSigLimit(), isFalse);
			expect(p.hasTxSizeCostPerByte(), isFalse);
			expect(p.hasSigVerifyCostEd25519(), isFalse);
			expect(p.hasSigVerifyCostSecp256k1(), isFalse);
		});

		test('Params defaults/creators/errors', () {
			final def = authpb.Params.getDefault();
			expect(def, isA<authpb.Params>());
			final empty = authpb.Params().createEmptyInstance();
			expect(empty, isA<authpb.Params>());
			final list = authpb.Params.createRepeated();
			expect(list, isA<pb.PbList<authpb.Params>>());
			expect(() => authpb.Params.fromJson('not-json'), throwsA(isA<FormatException>()));
			expect(() => authpb.Params.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});

		test('GenesisState roundtrip and ensure/clear/defaults/copyWith', () {
			final g = GenesisState(
				params: authpb.Params(maxMemoCharacters: Int64(1)),
				accounts: [Any(typeUrl: 'acc', value: [0x01])],
			);
			final bz = g.writeToBuffer();
			final g2 = GenesisState.fromBuffer(bz);
			expect(g2.hasParams(), isTrue);
			expect(g2.params.maxMemoCharacters.toInt(), 1);
			expect(g2.accounts.first.typeUrl, 'acc');
			final ensured = g2.ensureParams();
			expect(identical(ensured, g2.params), isTrue);
			g2.accounts.add(Any(typeUrl: 'acc2'));
			expect(g2.accounts.length, 2);
			g2.accounts.clear();
			expect(g2.accounts.length, 0);
			final def = GenesisState.getDefault();
			expect(def, isA<GenesisState>());
			final empty = GenesisState().createEmptyInstance();
			expect(empty, isA<GenesisState>());
			final list = GenesisState.createRepeated();
			expect(list, isA<pb.PbList<GenesisState>>());
			final copied = g.copyWith((gg) => gg.params = authpb.Params(txSigLimit: Int64(10)));
			expect(copied.params.txSigLimit.toInt(), 10);
		});

		test('ModuleAccount has/clear/permissions list/json/clone/copyWith/defaults/errors', () {
			final m = ModuleAccount(
				baseAccount: BaseAccount(address: 'a'),
				name: 'n',
				permissions: ['x'],
			);
			expect(m.hasBaseAccount(), isTrue);
			expect(m.hasName(), isTrue);
			expect(m.permissions.length, 1);
			m.permissions.addAll(['y','z']);
			expect(m.permissions, ['x','y','z']);
			m.permissions.clear();
			expect(m.permissions.isEmpty, isTrue);
			m.clearBaseAccount();
			expect(m.hasBaseAccount(), isFalse);
			m.clearName();
			expect(m.hasName(), isFalse);
			m.ensureBaseAccount();
			expect(m.hasBaseAccount(), isTrue);
			final cloned = m.clone();
			expect(cloned, isA<ModuleAccount>());
			final copied = m.copyWith((mm) {
				mm.name = 'n2';
				mm.baseAccount = BaseAccount(address: 'b');
			});
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.contains('n2'), isTrue);
			final def = ModuleAccount.getDefault();
			expect(def, isA<ModuleAccount>());
			final empty = ModuleAccount().createEmptyInstance();
			expect(empty, isA<ModuleAccount>());
			final list = ModuleAccount.createRepeated();
			expect(list, isA<pb.PbList<ModuleAccount>>());
			expect(() => ModuleAccount.fromJson('not-json'), throwsA(isA<FormatException>()));
			expect(() => ModuleAccount.fromBuffer([0xFF]), throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
	});
} 