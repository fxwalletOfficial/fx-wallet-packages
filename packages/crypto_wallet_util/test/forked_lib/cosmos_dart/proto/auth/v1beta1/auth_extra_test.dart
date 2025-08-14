import 'dart:convert';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/auth/v1beta1/auth.pb.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/any.pb.dart';
import 'package:fixnum/fixnum.dart';

void main() {
	group('proto cosmos.auth.v1beta1 auth extra', () {
		test('BaseAccount has/clear/ensure/json/copyWith', () {
			final b = BaseAccount(
				address: 'addr',
				pubKey: Any(typeUrl: 't', value: [9]),
				accountNumber: Int64(3),
				sequence: Int64(4),
			);
			expect(b.hasAddress(), isTrue);
			expect(b.hasPubKey(), isTrue);
			expect(b.hasAccountNumber(), isTrue);
			expect(b.hasSequence(), isTrue);

			b.clearAddress();
			expect(b.hasAddress(), isFalse);
			b.clearPubKey();
			expect(b.hasPubKey(), isFalse);
			b.clearAccountNumber();
			expect(b.hasAccountNumber(), isFalse);
			b.clearSequence();
			expect(b.hasSequence(), isFalse);

			final ensuredPk = b.ensurePubKey();
			expect(ensuredPk, isA<Any>());

			final copied = b.copyWith((m) {
				m.address = 'cosmos1abc';
				m.accountNumber = Int64(8);
				m.sequence = Int64(9);
			});
			final jsonStr = jsonEncode(copied.writeToJsonMap());
			expect(jsonStr.contains('cosmos1abc'), isTrue);
		});

		test('ModuleAccount has/clear/permissions list/json', () {
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
			m.clearBaseAccount();
			expect(m.hasBaseAccount(), isFalse);
			m.clearName();
			expect(m.hasName(), isFalse);
			m.ensureBaseAccount();
			expect(m.hasBaseAccount(), isTrue);

			final jsonStr = jsonEncode(m.writeToJsonMap());
			expect(jsonStr.isNotEmpty, isTrue);
		});
	});
} 