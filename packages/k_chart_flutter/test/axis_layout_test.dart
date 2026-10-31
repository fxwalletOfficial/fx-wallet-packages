import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart_flutter/utils/axis_layout.dart';

void main() {
  group('fitGridRows', () {
    test('keeps the rows when each holds two labels and half a label of space',
        () {
      expect(fitGridRows(4, 270, 13.6), 4);
      expect(fitGridRows(4, 4 * 13.6 * 2.5, 13.6), 4);
    });

    test('drops rows on short charts so the top two prices do not overlap', () {
      // 120pt and 89pt charts with 13.6pt labels: 3 and 2 rows.
      expect(fitGridRows(4, 120, 13.6), 3);
      expect(fitGridRows(4, 89, 13.6), 2);
    });

    test('never returns fewer than one row or more than asked', () {
      expect(fitGridRows(4, 10, 13.6), 1);
      expect(fitGridRows(0, 300, 13.6), 1);
      expect(fitGridRows(4, double.nan, 13.6), 4);
      expect(fitGridRows(4, 300, 0), 4);
    });
  });

  group('roundAxisTicks', () {
    test('uses 1, 2 or 5 times a power of ten', () {
      // 9.2 over 4 steps is 2.3 per step, so the step rounds up to 5; over 5 steps it is 2.
      expect(roundAxisTicks(123.4, 132.6, 4), [125, 130]);
      expect(roundAxisTicks(123.4, 132.6, 5), [124, 126, 128, 130, 132]);
      expect(roundAxisTicks(119.2, 133.1, 3), [120, 125, 130]);
      expect(roundAxisTicks(0.38, 0.43, 4), [0.38, 0.4, 0.42]);
    });

    test('keeps ticks that sit on the ends of the range', () {
      expect(roundAxisTicks(1.1, 1.2, 1), [1.1, 1.2]);
      expect(roundAxisTicks(0.1, 0.3, 2), [0.1, 0.2, 0.3]);
      expect(roundAxisTicks(0.3, 0.6, 3), [0.3, 0.4, 0.5, 0.6]);
    });

    test('keeps tiny prices free of float noise', () {
      expect(roundAxisTicks(0.0000047, 0.0000061, 2), [0.000005, 0.000006]);
      expect(roundAxisTicks(0.00000047, 0.00000061, 4),
          [0.0000005, 0.00000055, 0.0000006]);
    });

    test('never returns more than maxSteps + 1 values', () {
      for (final steps in [1, 2, 3, 4, 6]) {
        expect(
            roundAxisTicks(0, 97, steps).length, lessThanOrEqualTo(steps + 1),
            reason: '$steps steps');
      }
    });

    test('returns nothing for a range it cannot split', () {
      expect(roundAxisTicks(1, 1, 4), isEmpty);
      expect(roundAxisTicks(2, 1, 4), isEmpty);
      expect(roundAxisTicks(double.nan, 1, 4), isEmpty);
      expect(roundAxisTicks(1, 2, 0), isEmpty);
      expect(roundAxisTicks(1e12, 1e12 + 1e-6, 4), isEmpty);
    });
  });
}
