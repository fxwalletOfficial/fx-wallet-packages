import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart_flutter/k_chart_flutter.dart';

KLineEntity _candle(double low, double high, {int time = 0}) =>
    KLineEntity.fromCustom(
        open: low, close: high, high: high, low: low, vol: 1, time: time);

double _width(String text) {
  final style = ChartStyle();
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

ChartPainter _painter(List<KLineEntity>? data,
        {double? xFrontPadding,
        double scaleX = 1,
        MainState mainState = MainState.NONE,
        String Function(double value)? dataFormat}) =>
    ChartPainter(
        style: ChartStyle(),
        lines: const [],
        isTrendLine: false,
        selectY: 0.0,
        data: data,
        scaleX: scaleX,
        scrollX: 0.0,
        isLongPass: false,
        selectX: 0.0,
        xFrontPadding: xFrontPadding,
        isOnTap: false,
        isTapShowInfoDialog: false,
        mainState: mainState,
        volHidden: true,
        secondaryState: SecondaryState.NONE,
        dataFormat: dataFormat);

/// Paints [painter] at 380 × 120, which leaves a 78px main chart, and returns
/// the front padding it painted with.
double _paint(ChartPainter painter) {
  painter.paint(Canvas(PictureRecorder()), const Size(380, 120));
  return painter.xFrontPadding;
}

String _wholeNumber(double value) => value.toStringAsFixed(0);

void main() {
  group('ChartPainter.measureFrontPadding', () {
    test('keeps 100 when there are no candles', () {
      expect(_paint(_painter(null)), ChartPainter.defaultFrontPadding);
      expect(_paint(_painter(const [])), ChartPainter.defaultFrontPadding);
    });

    test('keeps a padding the caller passes', () {
      expect(_paint(_painter([_candle(120, 130)], xFrontPadding: 40)), 40);
    });

    test('is the wider of the high and low labels plus the gap', () {
      String format(double value) =>
          '\$${value.toStringAsFixed(value < 10 ? 1 : 0)}';
      final painter =
          _painter([_candle(9.8, 10), _candle(9.9, 10.5)], dataFormat: format);

      // \$9.8 is wider than \$11 (10.5 rounded), so the low price decides.
      expect(_width(r'$9.8'), greaterThan(_width(r'$11')));
      expect(_paint(painter), _width(r'$9.8') + 8);
      expect(painter.measureFrontPadding(gap: 2), _width(r'$9.8') + 2);
    });

    test('stays as wide on screen at every zoom', () {
      final data = [_candle(120, 130), _candle(118, 126)];
      final padding = _paint(_painter(data));

      expect(_paint(_painter(data, scaleX: 0.5)), closeTo(padding * 2, 1e-9));
      expect(_paint(_painter(data, scaleX: 2)), closeTo(padding / 2, 1e-9));
    });

    test('without a formatter measures the axis\'s two decimals', () {
      // The first candle has one decimal, so the now-price label shows 12.5,
      // but the axis shows two decimals, up to 14.12 for its top line.
      final data = [_candle(1.5, 2.5), _candle(1.5, 12.5)];

      expect(_paint(_painter(data)), _width('14.12') + 8);
      expect(_width('14.12'), greaterThan(_width('12.5')));
    });

    test('makes room for the top label, which sits above the highest price',
        () {
      // With equal rows the top line of a 78px chart is labelled
      // 99 + 9 × 10 / 68 ≈ 100.3.
      final data = [_candle(90, 99), _candle(91, 98)];

      expect(
          _paint(_painter(data, dataFormat: _wholeNumber)), _width('100') + 8);
    });

    test('includes the Bollinger bands when the main chart shows them', () {
      final data = [
        _candle(40, 50)
          ..up = 1000
          ..dn = 30,
        _candle(41, 49)
          ..up = 900
          ..dn = 35,
      ];

      expect(
          _paint(_painter(data, dataFormat: _wholeNumber)), _width('51') + 8);
      expect(
          _paint(_painter(data,
              mainState: MainState.BOLL, dataFormat: _wholeNumber)),
          _width('1143') + 8);
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
