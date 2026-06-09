import 'package:flutter_test/flutter_test.dart';

import 'package:web3_webview_demo/data/dapps.dart';
import 'package:web3_webview_demo/data/url_utils.dart';
import 'package:web3_webview_demo/services/recent_visits.dart';
import 'package:web3_webview_demo/widgets/dapp_bookmark_grid.dart';

void main() {
  group('normalizeDAppUrl', () {
    test('passes through valid http(s) URLs', () {
      expect(normalizeDAppUrl('https://app.uniswap.org'),
          'https://app.uniswap.org');
      expect(normalizeDAppUrl('http://example.com/path'),
          'http://example.com/path');
    });

    test('prefixes https:// onto bare hosts', () {
      expect(normalizeDAppUrl('app.uniswap.org'), 'https://app.uniswap.org');
      expect(normalizeDAppUrl('uniswap.org/swap'), 'https://uniswap.org/swap');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeDAppUrl('  jup.ag  '), 'https://jup.ag');
    });

    test('rejects blank, scheme-less single words, and non-web schemes', () {
      expect(normalizeDAppUrl(''), isNull);
      expect(normalizeDAppUrl('   '), isNull);
      expect(normalizeDAppUrl('uniswap'), isNull);
      expect(normalizeDAppUrl('javascript:alert(1)'), isNull);
      expect(normalizeDAppUrl('ftp://files.example.com'), isNull);
    });
  });

  group('hostLabel', () {
    test('strips www. and the scheme', () {
      expect(hostLabel('https://www.opensea.io'), 'opensea.io');
      expect(hostLabel('https://app.uniswap.org/swap'), 'app.uniswap.org');
    });
  });

  group('filterDApps', () {
    test('returns the full catalogue for an empty query', () {
      expect(filterDApps(''), kDAppCatalog);
      expect(filterDApps('   ').length, kDAppCatalog.length);
    });

    test('matches on name, description, host, and category', () {
      expect(filterDApps('uniswap').map((e) => e.name), contains('Uniswap'));
      expect(filterDApps('SOLANA').map((e) => e.name), contains('Jupiter'));
      expect(filterDApps('opensea.io').map((e) => e.name), contains('OpenSea'));
      // description keyword
      expect(filterDApps('aggregator').map((e) => e.name), contains('1inch'));
    });

    test('returns empty for a no-match query', () {
      expect(filterDApps('zzzzz-no-such-dapp'), isEmpty);
    });
  });

  group('RecentVisits', () {
    test('records most-recent-first and de-duplicates by URL', () {
      final recent = RecentVisits();
      addTearDown(recent.dispose);

      recent.record(url: 'https://a.com', title: 'A');
      recent.record(url: 'https://b.com', title: 'B');
      recent.record(url: 'https://a.com', title: 'A again');

      expect(recent.visits.map((v) => v.url), ['https://a.com', 'https://b.com']);
      expect(recent.visits.first.title, 'A again');
    });

    test('honours the capacity bound', () {
      final recent = RecentVisits(capacity: 2);
      addTearDown(recent.dispose);

      recent.record(url: 'https://a.com', title: 'A');
      recent.record(url: 'https://b.com', title: 'B');
      recent.record(url: 'https://c.com', title: 'C');

      expect(recent.visits.length, 2);
      expect(recent.visits.map((v) => v.url), ['https://c.com', 'https://b.com']);
    });

    test('ignores blank URLs and supports clear', () {
      final recent = RecentVisits();
      addTearDown(recent.dispose);

      recent.record(url: '   ', title: 'blank');
      expect(recent.isEmpty, isTrue);

      recent.record(url: 'https://a.com', title: 'A');
      expect(recent.isEmpty, isFalse);

      recent.clear();
      expect(recent.isEmpty, isTrue);
    });

    test('notifies listeners on record and clear', () {
      final recent = RecentVisits();
      addTearDown(recent.dispose);

      var notifications = 0;
      recent.addListener(() => notifications++);

      recent.record(url: 'https://a.com', title: 'A');
      recent.clear();

      expect(notifications, 2);
    });
  });
}
