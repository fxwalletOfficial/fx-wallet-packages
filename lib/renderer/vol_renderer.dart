import 'package:flutter/material.dart';
import 'package:k_chart_flutter/k_chart_flutter.dart';

class VolRenderer extends BaseChartRenderer<VolumeEntity> {
  final VolumeRendererStyle style;

  VolRenderer({
    required super.chartRect,
    required super.maxValue,
    required super.minValue,
    required this.style,
    super.dataFormat
  }) : super(style: style);

  @override
  void drawChart(VolumeEntity lastPoint, VolumeEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    double r = style.width / 2;
    double top = getVolY(curPoint.vol);
    double bottom = chartRect.bottom;
    if (curPoint.vol != 0) {
      canvas.drawRect(
        Rect.fromLTRB(curX - r, top, curX + r, bottom),
        chartPaint..color = curPoint.close > curPoint.open ? style.colors.up : style.colors.down
      );
    }

    if (lastPoint.MA5Volume != 0) drawLine(lastPoint.MA5Volume, curPoint.MA5Volume, canvas, lastX, curX, style.colors.ma5);
    if (lastPoint.MA10Volume != 0) drawLine(lastPoint.MA10Volume, curPoint.MA10Volume, canvas, lastX, curX, style.colors.ma10);
  }

  double getVolY(double value) => (maxValue - value) * (chartRect.height / maxValue) + chartRect.top;

  @override
  void drawText(Canvas canvas, VolumeEntity data, double x) {
    TextSpan span = TextSpan(
      children: [
        TextSpan(text: "VOL:${NumberUtil.format(data.vol)}    ", style: getTextStyle(style.colors.vol)),
        if (data.MA5Volume.notNullOrZero) TextSpan(text: "MA5:${NumberUtil.format(data.MA5Volume!)}    ", style: getTextStyle(style.colors.ma5)),
        if (data.MA10Volume.notNullOrZero) TextSpan(text: "MA10:${NumberUtil.format(data.MA10Volume!)}    ", style: getTextStyle(style.colors.ma10))
      ]
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - style.padding.top));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    TextSpan span = TextSpan(text: "${NumberUtil.format(maxValue)}", style: textStyle);
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(chartRect.width - tp.width - style.padding.right, chartRect.top - style.padding.top));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom), Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //vol垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - style.padding.top), Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
