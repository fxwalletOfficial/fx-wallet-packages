import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/transaction/hns/data_type.dart';

void main() {
	group('HNS data types fromJson coverage', () {
		test('UTXO.fromJson full fields', () {
			final json = {
				'prevout': {'hash': 'abcd', 'index': '1'},
				'witness': ['w1', 'w2'],
				'sequence': '4294967295',
				'coin': {
					'version': '1',
					'height': '100',
					'value': '12345',
					'address': 'hns1...',
					'covenant': {'type': '2', 'action': 'OPEN', 'items': ['a', 'b']},
					'coinbase': true,
					'satoshis': '12345',
				},
				'path': {
					'account': '0',
					'change': true,
					'derivation': "m/44'/5353'/0'/0/0",
					'publicKey': '02abcd',
					'script': '0014...'
				},
				'market': true,
			};
			final utxo = UTXO.fromJson(json);
			expect(utxo.prevout.hash, 'abcd');
			expect(utxo.prevout.index, 1);
			expect(utxo.witness.length, 2);
			expect(utxo.sequence, 4294967295);
			expect(utxo.coin.version, 1);
			expect(utxo.coin.height, 100);
			expect(utxo.coin.value, 12345);
			expect(utxo.coin.address, contains('hns1'));
			expect(utxo.coin.covenant.action, 'OPEN');
			expect(utxo.coin.coinbase, isTrue);
			expect(utxo.coin.satoshis, 12345);
			expect(utxo.path.account, 0);
			expect(utxo.path.change, isTrue);
			expect(utxo.path.derivation, contains("44'"));
			expect(utxo.path.publicKey, startsWith('02'));
			expect(utxo.path.script, isNotEmpty);
			expect(utxo.market, isTrue);
		});

		test('UTXO.fromJson defaults and empty', () {
			final utxo = UTXO.fromJson({});
			expect(utxo.prevout.hash, '');
			expect(utxo.prevout.index, 0);
			expect(utxo.witness, isEmpty);
			expect(utxo.sequence, 0);
			expect(utxo.coin.address, '');
			expect(utxo.coin.height, 0);
			expect(utxo.coin.covenant.action, anyOf('NONE', isEmpty));
			expect(utxo.path.change, isFalse);
			expect(utxo.path.script, '');
			expect(utxo.market, isFalse);
		});

		test('Coin.fromJson string numbers and missing optionals', () {
			final coin = Coin.fromJson({
				'version': '2',
				'value': '999',
				'address': 'addr',
				'covenant': {'type': '0'},
				'coinbase': false,
			});
			expect(coin.version, 2);
			expect(coin.height, 0);
			expect(coin.value, 999);
			expect(coin.covenant.type, 0);
			expect(coin.satoshis, 0);
		});

		test('Prevout/Path/Vout/Covenant fromJson mixed inputs', () {
			final prev = Prevout.fromJson({'hash': 'h', 'index': '3'});
			expect(prev.index, 3);

			final path = Path.fromJson({
				'account': '1',
				'change': false,
				'derivation': 'm/...',
				'publicKey': '02ff',
			});
			expect(path.account, 1);
			expect(path.script, '');

			final vout = Vout.fromJson({
				'value': '10',
				'amount': '12.5',
				'address': 'h...',
				'covenant': {'type': '1', 'action': 'REDEEM', 'items': ['x']},
				'encode': 'enc',
				'script': 'scr',
			});
			expect(vout.value, 10);
			expect(vout.amount, closeTo(12.5, 0.000001));
			expect(vout.covenant.items, contains('x'));

			final cov = Covenant.fromJson({'type': '7'});
			expect(cov.type, 7);
			expect(cov.action, 'NONE');
			expect(cov.items, isEmpty);
		});

		group('TRX message json types', () {
			test('TrxMessageToSign/TrxRawData/Trx... nested full', () {
				final json = {
					'visible': true,
					'txID': '0xabc',
					'raw_data': {
						'contract': [
							{
								'parameter': {
									'value': {
										'amount': '100',
										'owner_address': 'ow',
										'to_address': 'to'
									},
									'type_url': 'type'
								},
								'type': 'TransferContract'
							}
						],
						'ref_block_bytes': 'bb',
						'ref_block_hash': 'hh',
						'expiration': '11',
						'timestamp': '22'
					},
					'raw_data_hex': '0x00',
					'initTokenAddress': 'token',
					'transaction': 'tx',
					'blockhash': 'bh',
					'lastValidBlockHeight': 'lv',
					'stakeAccountPriv': 'priv',
					'stakeAccountPub': 'pub'
				};
				final m = TrxMessageToSign.fromJson(json);
				expect(m.visible, isTrue);
				expect(m.txID, '0xabc');
				expect(m.rawData.contract.length, 1);
				expect(m.rawData.refBlockBytes, 'bb');
				expect(m.rawData.expiration, 11);
				expect(m.rawData.timestamp, 22);
				expect(m.initTokenAddress, 'token');
				expect(m.blockHash, 'bh');
			});

			test('Trx... defaults and empty lists', () {
				final m = TrxMessageToSign.fromJson({});
				expect(m.visible, isFalse);
				expect(m.txID, '');
				expect(m.rawData.contract, isEmpty);
				expect(m.rawData.refBlockHash, '');
				final c = TrxContract.fromJson({});
				expect(c.type, '');
				final p = TrxParameter.fromJson({});
				expect(p.typeUrl, '');
				final v = TrxValue.fromJson({});
				expect(v.amount, 0);
				expect(v.ownerAddress, '');
				expect(v.toAddress, '');
			});
		});
	});
} 