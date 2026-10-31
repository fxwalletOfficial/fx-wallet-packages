import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart_flutter/k_chart_flutter.dart';

KLineEntity _candle(double low, double high, {int time = 0}) =>
    KLineEntity.fromCustom(
        open: low, close: high, high: high, low: low, vol: 1, time: time);

double _width(String text, ChartStyle style) {
  final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: style.dataFontSize, fontFamily: style.fontFamily)),
      textDirection: TextDirection.ltr)
    ..layout();
  final width = tp.width;
  tp.dispose();
  return width;
}

void main() {
  group('ChartPainter.autoFrontPadding', () {
    final style = ChartStyle();

    test('keeps 100 when there are no candles', () {
      expect(ChartPainter.autoFrontPadding(data: null, style: style),
          ChartPainter.defaultFrontPadding);
      expect(ChartPainter.autoFrontPadding(data: const [], style: style),
          ChartPainter.defaultFrontPadding);
    });

    test('is the wider of the high and low labels plus the gap', () {
      String format(double value) =>
          '\$${value.toStringAsFixed(value < 10 ? 1 : 0)}';
      final data = [_candle(9.8, 10), _candle(9.9, 10.5)];

      // \$9.8 is wider than \$11 (10.5 rounded), so the low price decides.
      expect(_width(r'$9.8', style), greaterThan(_width(r'$11', style)));
      expect(
          ChartPainter.autoFrontPadding(
              data: data, style: style, dataFormat: format),
          _width(r'$9.8', style) + 8);
      expect(
          ChartPainter.autoFrontPadding(
              data: data, style: style, dataFormat: format, gap: 2),
          _width(r'$9.8', style) + 2);
    });

    test('without a formatter uses the first candle\'s decimals, like the axis',
        () {
      final data = [_candle(1.25, 1.5), _candle(1.2, 12.75)];
      expect(ChartPainter.autoFrontPadding(data: data, style: style),
          _width('12.75', style) + 8);
    });
  });

  testWidgets(
      'a short chart with round ticks and a measured front padding paints without errors',
      (tester) async {
    final data = [
      for (var i = 0; i < 60; i++)
        _candle(120 + i % 7, 124 + i % 9, time: i * 3600000)
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 380,
          height: 120,
          child: KChartWidget(
            data: data,
            isTrendLine: false,
            xFrontPadding: null,
            mainState: MainState.NONE,
            volHidden: true,
            secondaryState: SecondaryState.NONE,
            style: ChartStyle(roundYAxisTicks: true),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
