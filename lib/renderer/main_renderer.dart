import 'package:flutter/material.dart';

import '../entity/candle_entity.dart';
import '../k_chart_widget.dart' show MainState;
import 'base_chart_renderer.dart';

//For TrendLine
double? trendLineMax;
double? trendLineScale;
double? trendLineContentRec;

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  final MainRendererStyle style;
  final MainState state;
  final bool isLine;

  //绘制的内容区域
  late Rect _contentRect;
  double _contentPadding = 5.0;
  List<int> maDayList;

  final double mLineStrokeWidth = 1.0;
  double scaleX;
  late Paint mLinePaint;

  MainRenderer({
    required this.style,
    required super.chartRect,
    required super.maxValue,
    required super.minValue,
    this.state = MainState.NONE,
    this.isLine = false,
    required this.scaleX,
    this.maDayList = const [5, 10, 20],
    super.dataFormat
  }) : super(style: style) {
    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = style.colors.kLine;

    _contentRect = Rect.fromLTRB(chartRect.left, chartRect.top + _contentPadding, chartRect.right, chartRect.bottom - _contentPadding);

    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }

    scaleY = _contentRect.height / (maxValue - minValue);
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine) return;

    TextSpan? span;
    if (state == MainState.MA) {
      span = TextSpan(children: _createMATextSpan(data));
    } else if (state == MainState.BOLL) {
      span = TextSpan(
        children: [
          if (data.up != 0) TextSpan(text: 'BOLL:${format(data.mb)}    ', style: getTextStyle(style.colors.ma5)),
          if (data.mb != 0) TextSpan(text: 'UB:${format(data.up)}    ', style: getTextStyle(style.colors.ma10)),
          if (data.dn != 0)TextSpan(text: 'LB:${format(data.dn)}    ', style: getTextStyle(style.colors.ma30)),
        ]
      );
    }

    if (span == null) return;
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - style.padding.top + style.fontSize / 2));
  }

  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      if (data.maValueList?[i] != 0) {
        var item = TextSpan(text: 'MA${maDayList[i]}:${format(data.maValueList![i])}    ', style: getTextStyle(style.getMAColor(i)));
        result.add(item);
      }
    }
    return result;
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX, double curX, Size size, Canvas canvas) {
    if (isLine) {
      drawPolyLine(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);
      if (state == MainState.MA) {
        drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
      } else if (state == MainState.BOLL) {
        drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
      }
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  //画折线图
  void drawPolyLine(double lastPrice, double curPrice, Canvas canvas, double lastX, double curX) {
    mLinePath ??= Path();

    if (lastX == curX) lastX = 0; //起点位置填充
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));

    //画阴影
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [style.colors.lineFill, style.colors.lineFillInside],
    ).createShader(Rect.fromLTRB(chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint..shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lastPrice));
    mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(mLinePath!, mLinePaint..strokeWidth = (mLineStrokeWidth / scaleX).clamp(0.1, 1.0));
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas, double lastX, double curX) {
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) break;

      if (lastPoint.maValueList?[i] != 0) {
        drawLine(lastPoint.maValueList?[i], curPoint.maValueList?[i], canvas, lastX, curX, style.getMAColor(i));
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0) drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX, style.colors.ma10);
    if (lastPoint.mb != 0) drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX, style.colors.ma5);
    if (lastPoint.dn != 0) drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX, style.colors.ma30);
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = style.candleWidth / 2;
    double lineR = style.candleLineWidth / 2;

    if (open >= close) {
      // 实体高度>= CandleLineWidth
      if (open - close < style.candleLineWidth) open = close + style.candleLineWidth;

      chartPaint.color = style.colors.up;
      canvas.drawRect(Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else if (close > open) {
      // 实体高度>= CandleLineWidth
      if (close - open < style.candleLineWidth) open = close - style.candleLineWidth;

      chartPaint.color = style.colors.down;
      canvas.drawRect(Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;
      TextSpan span = TextSpan(text: format(value), style: textStyle);
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      double offsetX;
      switch (style.yAxisAlignment) {
        case VerticalTextAlignment.left:
          offsetX = style.padding.left;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width - style.padding.right;
          break;
      }

      if (i == 0) {
        tp.paint(canvas, Offset(offsetX, style.padding.top));
      } else {
        tp.paint(
            canvas, Offset(offsetX, rowSpace * i - tp.height + style.padding.top));
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
//    final int gridRows = 4, gridColumns = 4;
    double rowSpace = chartRect.height / gridRows;
    canvas.drawLine(Offset(0, 0), Offset(chartRect.width, 0), gridPaint);
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + style.padding.top),
          Offset(chartRect.width, rowSpace * i + style.padding.top), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, 0),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    //For TrendLine
    updateTrendLineData();
    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
