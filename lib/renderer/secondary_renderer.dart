import 'package:flutter/material.dart';

import '../entity/macd_entity.dart';
import '../k_chart_widget.dart' show SecondaryState;
import 'base_chart_renderer.dart';

class SecondaryRenderer extends BaseChartRenderer<MACDEntity> {
  final SecondaryState state;
  final SecondaryRendererStyle style;

  SecondaryRenderer({
    required super.chartRect,
    required super.maxValue,
    required super.minValue,
    required this.state,
    required this.style,
    super.dataFormat
  }) : super(style: style);

  @override
  void drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    switch (state) {
      case SecondaryState.MACD:
        drawMACD(curPoint, canvas, curX, lastPoint, lastX);
        break;

      case SecondaryState.KDJ:
        drawLine(lastPoint.k, curPoint.k, canvas, lastX, curX, style.colors.k);
        drawLine(lastPoint.d, curPoint.d, canvas, lastX, curX, style.colors.d);
        drawLine(lastPoint.j, curPoint.j, canvas, lastX, curX, style.colors.j);
        break;

      case SecondaryState.RSI:
        drawLine(lastPoint.rsi, curPoint.rsi, canvas, lastX, curX, style.colors.rsi);
        break;

      case SecondaryState.WR:
        drawLine(lastPoint.r, curPoint.r, canvas, lastX, curX, style.colors.rsi);
        break;

      case SecondaryState.CCI:
        drawLine(lastPoint.cci, curPoint.cci, canvas, lastX, curX, style.colors.rsi);
        break;

      default:
        break;
    }
  }

  void drawMACD(MACDEntity curPoint, Canvas canvas, double curX, MACDEntity lastPoint, double lastX) {
    final macd = curPoint.macd ?? 0;
    double macdY = getY(macd);
    double r = style.macdWidth / 2;
    double zeroY = getY(0);
    if (macd > 0) {
      canvas.drawRect(Rect.fromLTRB(curX - r, macdY, curX + r, zeroY), chartPaint..color = style.colors.up);
    } else {
      canvas.drawRect(Rect.fromLTRB(curX - r, zeroY, curX + r, macdY), chartPaint..color = style.colors.down);
    }

    if (lastPoint.dif != 0) drawLine(lastPoint.dif, curPoint.dif, canvas, lastX, curX, style.colors.dif);
    if (lastPoint.dea != 0) drawLine(lastPoint.dea, curPoint.dea, canvas, lastX, curX, style.colors.dea);
  }

  @override
  void drawText(Canvas canvas, MACDEntity data, double x) {
    List<TextSpan>? children;
    switch (state) {
      case SecondaryState.MACD:
        children = [
          TextSpan(text: "MACD(12,26,9)    ", style: getTextStyle(style.colors.defaultText)),
          if (data.macd != 0) TextSpan(text: "MACD:${format(data.macd)}    ", style: getTextStyle(style.colors.macd)),
          if (data.dif != 0) TextSpan(text: "DIF:${format(data.dif)}    ", style: getTextStyle(style.colors.dif)),
          if (data.dea != 0) TextSpan(text: "DEA:${format(data.dea)}    ", style: getTextStyle(style.colors.dea))
        ];
        break;
      case SecondaryState.KDJ:
        children = [
          TextSpan(text: "KDJ(9,1,3)    ", style: getTextStyle(style.colors.defaultText)),
          if (data.macd != 0) TextSpan(text: "K:${format(data.k)}    ", style: getTextStyle(style.colors.k)),
          if (data.dif != 0) TextSpan(text: "D:${format(data.d)}    ", style: getTextStyle(style.colors.d)),
          if (data.dea != 0) TextSpan(text: "J:${format(data.j)}    ", style: getTextStyle(style.colors.j))
        ];
        break;
      case SecondaryState.RSI:
        children = [
          TextSpan(text: "RSI(14):${format(data.rsi)}    ", style: getTextStyle(style.colors.rsi))
        ];
        break;
      case SecondaryState.WR:
        children = [
          TextSpan(text: "WR(14):${format(data.r)}    ", style: getTextStyle(style.colors.rsi))
        ];
        break;
      case SecondaryState.CCI:
        children = [
          TextSpan(text: "CCI(14):${format(data.cci)}    ", style: getTextStyle(style.colors.rsi))
        ];
        break;
      default:
        break;
    }
    TextPainter tp = TextPainter(text: TextSpan(children: children ?? []), textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - style.padding.top));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    final maxTp = TextPainter(text: TextSpan(text: "${format(maxValue)}", style: textStyle), textDirection: TextDirection.ltr);
    maxTp.layout();
    final minTp = TextPainter(text: TextSpan(text: "${format(minValue)}", style: textStyle), textDirection: TextDirection.ltr);
    minTp.layout();

    maxTp.paint(canvas, Offset(chartRect.width - maxTp.width - style.padding.right, chartRect.top - style.padding.top));
    minTp.paint(canvas, Offset(chartRect.width - minTp.width - style.padding.right, chartRect.bottom - minTp.height));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.top), Offset(chartRect.width, chartRect.top), gridPaint);
    canvas.drawLine(Offset(0, chartRect.bottom), Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //mSecondaryRect垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - style.padding.top), Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
