import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/typed_data/abi_decoder.dart';

String z(int n) => List.generate(n, (_) => '0').join();
String word(String hexNo0x) => hexNo0x.padLeft(64, '0'); // 32-byte word
String wordInt(int v) => v.toRadixString(16).padLeft(64, '0');
String bytesHex(String hexNo0x) {
	final len = (hexNo0x.length ~/ 2);
	final lenWord = wordInt(len);
	final pad = ((32 - (len % 32)) % 32) * 2;
	return lenWord + hexNo0x + z(pad);
}

void main() {
	group('AbiDecoder static parameters', () {
		test('address/uint256/bool/bytes32 decode', () {
			final abi = [
				{
					'type': 'function',
					'name': 'foo',
					'inputs': [
						{'name':'a','type':'address'},
						{'name':'b','type':'uint256'},
						{'name':'c','type':'bool'},
						{'name':'d','type':'bytes32'},
					]
				}
			];
			final dec = AbiDecoder.fromABI(abi);
			final sig4 = AbiDecoder.compute4BytesSignature('foo(address,uint256,bool,bytes32)');
			// address: ...0001
			final a = word('0000000000000000000000000000000000000001');
			final b = wordInt(2);
			final c = wordInt(1); // true
			final d = '11'.padLeft(64, '1');
			final data = sig4 + a + b + c + d;
			final res = dec.decodeParameters(data);
			expect(res?['function'], 'foo');
			expect((res?['parameters'] as List)[0]['value'], '0x0000000000000000000000000000000000000001');
			expect((res?['parameters'] as List)[1]['value'].toString(), '2');
			expect((res?['parameters'] as List)[2]['value'], true);
			expect((res?['parameters'] as List)[3]['value'], startsWith('0x'));
		});
	});

	group('AbiDecoder dynamic bytes/string', () {
		test('bar(bytes,string)', () {
			final abi = [
				{
					'type': 'function',
					'name': 'bar',
					'inputs': [
						{'name':'b','type':'bytes'},
						{'name':'s','type':'string'},
					]
				}
			];
			final dec = AbiDecoder.fromABI(abi);
			final sig4 = AbiDecoder.compute4BytesSignature('bar(bytes,string)');
			// head: offsets 0x40 and 0x40 + bytes section size
			final head1 = wordInt(0x40);
			final bytesData = bytesHex('abcdef'); // length=3, data ab cd ef
			final head2 = wordInt(0x40 + (bytesData.length ~/ 2));
			final strData = bytesHex('6869'); // "hi"
			final data = sig4 + head1 + head2 + bytesData + strData;
			final res = dec.decodeParameters(data);
			final params = (res?['parameters'] as List);
			expect(params[0]['value'], '0xabcdef');
			expect(params[1]['value'], 'hi');
		});
	});

	group('AbiDecoder tuples', () {
		test('static tuple (address,uint256)', () {
			final abi = [
				{
					'type': 'function',
					'name': 'baz',
					'inputs': [
						{
							'name':'t','type':'tuple',
							'components': [
								{'name':'a','type':'address'},
								{'name':'b','type':'uint256'}
							]
						}
					]
				}
			];
			final dec = AbiDecoder.fromABI(abi);
			final sig4 = AbiDecoder.compute4BytesSignature('baz((address,uint256))');
			final a = word('0000000000000000000000000000000000000002');
			final b = wordInt(7);
			final data = sig4 + a + b;
			final res = dec.decodeParameters(data);
			final vals = ((res?['parameters'] as List)[0]['value'] as List);
			expect(vals[0]['value'], '0x0000000000000000000000000000000000000002');
			expect(vals[1]['value'].toString(), '7');
		});

		test('dynamic tuple (string,uint256)', () {
			final abi = [
				{
					'type': 'function',
					'name': 'qux',
					'inputs': [
						{
							'name':'t','type':'tuple',
							'components': [
								{'name':'s','type':'string'},
								{'name':'n','type':'uint256'}
							]
						}
					]
				}
			];
			final dec = AbiDecoder.fromABI(abi);
			final sig4 = AbiDecoder.compute4BytesSignature('qux((string,uint256))');
			// head: pointer to tuple at 0x20
			final head = wordInt(0x20);
			// tuple head: pointer to string at 0x40, uint=5
			final tupPtr = wordInt(0x40);
			final tupNum = wordInt(5);
			// string data at tuple base + 0x40
			final tupStr = bytesHex('6f6b'); // "ok"
			final data = sig4 + head + tupPtr + tupNum + tupStr;
			final res = dec.decodeParameters(data);
			final vals = ((res?['parameters'] as List)[0]['value'] as List);
			expect(vals[0]['value'], 'ok');
			expect(vals[1]['value'].toString(), '5');
		});
	});

	group('AbiDecoder misc and errors', () {
		test('hasFunction/functions/signatures and error decodeParameters returns error map', () {
			final abi = [
				{
					'type': 'function', 'name': 'x', 'inputs': [ {'name':'b','type':'bytes'} ]
				}
			];
			final dec = AbiDecoder.fromABI(abi);
			final sig4 = AbiDecoder.compute4BytesSignature('x(bytes)');
			expect(dec.hasFunction(sig4), isTrue);
			expect(dec.functions.isNotEmpty, isTrue);
			expect(dec.signatures.isNotEmpty, isTrue);
			// Provide unknown selector to trigger null path
			final res = dec.decodeParameters('0xdeadbeef');
			expect(res, isNull);
		});
	});
} 