import 'dart:convert';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/util.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/models.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/constants.dart';

void main() {
	group('TypedDataUtil hashMessage', () {
		test('V1 with array and single object', () {
			final td = [
				{'type':'string','name':'a','value':'x'},
				{'type':'bytes','name':'b','value':'0x0102'}
			];
			final h1 = TypedDataUtil.hashMessage(jsonData: jsonEncode(td), version: TypedDataVersion.V1);
			expect(h1.length, 32);
			final h2 = TypedDataUtil.hashMessage(jsonData: jsonEncode(td.first), version: TypedDataVersion.V1);
			expect(h2.length, 32);
		});

		test('bad json throws', () {
			expect(() => TypedDataUtil.hashMessage(jsonData: '{', version: TypedDataVersion.V3), throwsArgumentError);
		});

		test('V3/V4 domain+message', () {
			final types = <String, List<TypedDataField>>{
				'EIP712Domain': [
					TypedDataField(name: 'name', type: 'string'),
					TypedDataField(name: 'version', type: 'string'),
				],
				'Person': [
					TypedDataField(name: 'wallet', type: 'address'),
					TypedDataField(name: 'age', type: 'uint256'),
				]
			};
			final message = {
				'wallet':'0x0000000000000000000000000000000000000001',
				'age':'18'
			};
			final domain = {'name':'Demo','version':'1'};
			final obj = {'types': types.map((k,v)=> MapEntry(k, v.map((e)=> e.toJson()).toList())),'primaryType':'Person','domain':domain,'message':message};
			final j = jsonEncode(obj);
			final v3 = TypedDataUtil.hashMessage(jsonData: j, version: TypedDataVersion.V3);
			expect(v3.length, 32);
			final v4 = TypedDataUtil.hashMessage(jsonData: j, version: TypedDataVersion.V4);
			expect(v4.length, 32);
		});
	});

	group('TypedDataUtil type/encode helpers', () {
					test('encodeType/findTypeDependencies errors and success', () {
			final types = <String, List<TypedDataField>>{
				'EIP712Domain':[TypedDataField(name:'name', type:'string')],
				'X':[TypedDataField(name:'a', type:'string')]
			};
			expect(() => TypedDataUtil.encodeType('Y', types), throwsArgumentError);
			final e = TypedDataUtil.encodeType('X', types);
			expect(e.startsWith('X('), isTrue);
			final deps = TypedDataUtil.findTypeDependencies('X', types);
			expect(deps.contains('X'), isTrue);
		});

					test('encodeData V4 bytes/string/array/object and V3 array unsupported', () {
			final types = <String, List<TypedDataField>>{
				'EIP712Domain':[TypedDataField(name:'name', type:'string')],
				'X':[TypedDataField(name:'a', type:'bytes'),TypedDataField(name:'b', type:'string'),TypedDataField(name:'arr', type:'uint256[]')]
			};
			final data = {'a':'0x0102', 'b':'hi', 'arr':[1,2,3]};
			final encV4 = TypedDataUtil.encodeData('X', data, types, 'V4');
			expect(encV4.length, greaterThan(0));
			expect(() => TypedDataUtil.encodeData('X', data, types, 'V3'), throwsArgumentError);
		});
	});

	group('TypedDataUtil typedSignatureHash', () {
		test('bytes hex/non-hex and other', () {
			final list = [
				EIP712TypedData(type: 'bytes', name: 'b1', value: '0x0102'),
				EIP712TypedData(type: 'bytes', name: 'b2', value: 'hi'),
				EIP712TypedData(type: 'string', name: 's', value: 'ok')
			];
			final h = TypedDataUtil.typedSignatureHash(list);
			expect(h.length, 32);
		});
	});
} 