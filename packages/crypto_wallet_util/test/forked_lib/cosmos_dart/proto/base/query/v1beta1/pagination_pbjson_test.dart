import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/cosmos/base/query/v1beta1/pagination.pbjson.dart' as pjson;

void main() {
	group('cosmos.base.query.v1beta1 pagination.pbjson', () {
		test('JSON maps and descriptors', () {
			expect(pjson.pageRequestDescriptor.isNotEmpty, isTrue);
			expect(pjson.pageResponseDescriptor.isNotEmpty, isTrue);
		});
	});
}