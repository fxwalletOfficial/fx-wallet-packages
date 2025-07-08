import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';

import 'package:k_chart_flutter/entity/info_window_entity.dart';
import 'package:k_chart_flutter/entity/k_line_entity.dart';
import 'package:k_chart_flutter/renderer/base_chart_painter.dart';
import 'package:k_chart_flutter/renderer/base_chart_renderer.dart';
import 'package:k_chart_flutter/renderer/main_renderer.dart';
import 'package:k_chart_flutter/renderer/secondary_renderer.dart';
import 'package:k_chart_flutter/renderer/vol_renderer.dart';
import 'package:k_chart_flutter/utils/date_format_util.dart';
import 'package:k_chart_flutter/utils/number_util.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

double trendLineX = 0;

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  bool isRecordingCord = false; //For TrendLine
  final double selectY; //For TrendLine
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  List<int> maDayList;
  late Paint selectPointPaint;
  late Paint selectorBorderPaint;
  late Paint nowPricePaint;
  final ChartStyle style;
  final bool hideGrid;
  final bool showNowPrice;

  final String Function(double value)? dataFormat;

  ChartPainter({
    required this.style,
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required data,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    isOnTap,
    isTapShowInfoDialog,
    mainState,
    volHidden,
    secondaryState,
    this.sink,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.maDayList = const [5, 10, 20],
    this.dataFormat
  }) : super(
    style: style,
    data: data,
    scaleX: scaleX,
    scrollX: scrollX,
    isLongPress: isLongPass,
    isOnTap: isOnTap,
    isTapShowInfoDialog: isTapShowInfoDialog,
    selectX: selectX,
    mainState: mainState,
    volHidden: volHidden,
    secondaryState: secondaryState,
    xFrontPadding: xFrontPadding,
    isLine: isLine
  ) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = style.select.colors.fill;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = style.select.colors.border;
    nowPricePaint = Paint()
      ..strokeWidth = style.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    mMainRenderer = MainRenderer(
      chartRect: mMainRect,
      maxValue: mMainMaxValue,
      minValue: mMainMinValue,
      state: mainState,
      isLine: isLine,
      style: style.main,
      scaleX: scaleX,
      maDayList: maDayList,
      dataFormat: dataFormat
    );
    if (mVolRect != null) mVolRenderer = VolRenderer(
      chartRect: mVolRect!,
      maxValue: mVolMaxValue,
      minValue: mVolMinValue,
      style: style.volume,
      dataFormat: dataFormat
    );

    if (mSecondaryRect != null) {
      mSecondaryRenderer = SecondaryRenderer(
        chartRect: mSecondaryRect!,
        maxValue: mSecondaryMaxValue,
        minValue: mSecondaryMinValue,
        state: secondaryState,
        style: style.secondary,
        dataFormat: dataFormat
      );
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint();
    Gradient mBgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: style.colors.background
    );
    Rect mainRect = Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + style.main.padding.top);
    canvas.drawRect(mainRect, mBgPaint..shader = mBgGradient.createShader(mainRect));

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(0, mVolRect!.top - style.volume.padding.top, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(volRect, mBgPaint..shader = mBgGradient.createShader(volRect));
    }

    if (mSecondaryRect != null) {
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect!.top - style.secondary.padding.top, mSecondaryRect!.width, mSecondaryRect!.bottom);
      canvas.drawRect(secondaryRect, mBgPaint..shader = mBgGradient.createShader(secondaryRect));
    }
    Rect dateRect = Rect.fromLTRB(0, size.height - style.main.padding.bottom, size.width, size.height);
    canvas.drawRect(dateRect, mBgPaint..shader = mBgGradient.createShader(dateRect));
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      mSecondaryRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; data != null && i <= mStopIndex; i++) {
      KLineEntity? curPoint = data?[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : data![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mSecondaryRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
    }

    if ((isLongPress || (isTapShowInfoDialog && isOnTap)) && !isTrendLine) drawCrossLine(canvas, size);
    if (isTrendLine) drawTrendLines(canvas, size);
    canvas.restore();
  }

  @override
  void drawVerticalText(canvas) {
    var textStyle = getTextStyle(style.colors.defaultText);
    if (!hideGrid) mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);

    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    mSecondaryRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (data == null) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (data?[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(data![index].time), null);
        y = size.height - (style.main.padding.bottom - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    final index = calculateSelectedX(selectX);
    final point = getItem(index);

    final tp = getTextPainter(format(point.close), style.select.colors.text);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      Path path = new Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      Path path = new Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    final dateTp = getTextPainter(getDate(point.time), style.select.colors.text);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - style.main.padding.bottom;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1, y + baseLine + r), selectPointPaint);
    canvas.drawRect(Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1, y + baseLine + r), selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //长按显示按中的数据
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //松开显示最后一条数据
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine) return;
    double lineSize = 20;
    double lineToTextOffset = 5;

    Paint linePaint = Paint()
      ..strokeWidth = 1
      ..color = style.colors.minColor;

    //绘制最大值和最小值
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      final tp = getTextPainter(format(mMainLowMinValue), style.colors.minColor);
      canvas.drawLine(Offset(x, y), Offset(x + lineSize, y), linePaint);
      tp.paint(canvas, Offset(x + lineSize + lineToTextOffset, y - tp.height / 2));
    } else {
      final tp = getTextPainter(format(mMainLowMinValue), style.colors.minColor);
      canvas.drawLine(Offset(x, y), Offset(x - lineSize, y), linePaint);
      tp.paint(canvas, Offset(x - tp.width - lineSize - lineToTextOffset, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(format(mMainHighMaxValue), style.colors.maxColor);

      canvas.drawLine(Offset(x, y), Offset(x + lineSize, y), linePaint);

      tp.paint(canvas, Offset(x + lineSize + lineToTextOffset, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(format(mMainHighMaxValue), style.colors.maxColor);
      canvas.drawLine(Offset(x, y), Offset(x - lineSize, y), linePaint);
      tp.paint(canvas, Offset(x - tp.width - lineSize - lineToTextOffset, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!showNowPrice || data == null) return;

    double value = data!.last.close;
    double y = getMainY(value);

    //视图展示区域边界值绘制
    if (y > getMainY(mMainLowMinValue)) y = getMainY(mMainLowMinValue);
    if (y < getMainY(mMainHighMaxValue)) y = getMainY(mMainHighMaxValue);

    nowPricePaint
      ..color = value >= data!.last.open ? style.colors.nowPriceUp : style.colors.nowPriceDown;
    //先画横线
    double startX = 0;
    final max = -mTranslateX + mWidth / scaleX;
    final space = style.nowPriceLineSpan + style.nowPriceLineLength;
    while (startX < max) {
      canvas.drawLine(Offset(startX, y), Offset(startX + style.nowPriceLineLength, y), nowPricePaint);
      startX += space;
    }

    //再画背景和文本
    TextPainter tp = getTextPainter(format(value), style.colors.nowPriceText);

    double offsetX;
    switch (style.main.yAxisAlignment) {
      case VerticalTextAlignment.left:
        offsetX = 0;
        break;

      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width;
        break;
    }

    double top = y - tp.height / 2;
    canvas.drawRect(Rect.fromLTRB(offsetX, top, offsetX + tp.width, top + tp.height), nowPricePaint);
    tp.paint(canvas, Offset(offsetX, top));
  }

  /// For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    trendLineX = x;

    double y = selectY;

    // k线图竖线
    canvas.drawLine(Offset(x, style.main.padding.top), Offset(x, size.height - style.main.padding.bottom), paintY);
    Paint paintX = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), height: 15.0 * scaleX, width: 15.0), paint);
    } else {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), height: 10.0, width: 10.0 / scaleX), paint);
    }
    if (lines.length >= 1) {
      lines.forEach((element) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        var p1 = Offset(element.p1.dx, a);
        var p2 = Offset(element.p2.dx, b);
        canvas.drawLine(p1, element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
          Paint()
            ..color = Colors.yellow
            ..strokeWidth = 2
        );
      });
    }
  }

  /// 画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    final index = calculateSelectedX(selectX);
    final point = getItem(index);
    final x = getX(index);
    final y = getMainY(point.close);

    // Draw y line.
    final yStyle = style.select.y;
    final paintY = Paint()
      ..color = yStyle.color
      ..strokeWidth = yStyle.width
      ..isAntiAlias = true;


    if (yStyle.length <= 0 || yStyle.span <= 0) {
      canvas.drawLine(Offset(x, style.main.padding.top), Offset(x, size.height - style.main.padding.bottom), paintY);
    } else {
      double startY = style.main.padding.top;
      final maxY = size.height - style.main.padding.bottom;
      final spaceY = yStyle.length + yStyle.span;
      while (startY < maxY) {
        canvas.drawLine(Offset(x, startY), Offset(x, startY + yStyle.length), paintY);
        startY  += spaceY;
      }
    }

    // Draw x line.
    final xStyle = style.select.x;
    final paintX = Paint()
      ..color = xStyle.color
      ..strokeWidth = xStyle.width
      ..isAntiAlias = true;

    if (xStyle.length <= 0 || xStyle.span <= 0) {
      canvas.drawLine(Offset(-mTranslateX, y), Offset(-mTranslateX + mWidth, y), paintX);
    } else {
      double startX = 0;
      final maxX = -mTranslateX + mWidth;
      final spaceX = xStyle.length + xStyle.span;
      while (startX < maxX) {
        canvas.drawLine(Offset(startX, y), Offset(startX + xStyle.length, y), paintX);
        startX += spaceX;
      }
    }

    // Draw dot.
    final paintD = Paint()
      ..color = style.select.dot.color
      ..strokeWidth = style.select.dot.diameter
      .. isAntiAlias = true;

    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), height: style.select.dot.diameter, width: style.select.dot.diameter), paintD);
  }

  TextPainter getTextPainter(text, color) {
    if (color == null) color = style.colors.defaultText;

    final tp = TextPainter(
      text: TextSpan(text: "$text", style: getTextStyle(color)),
      textDirection: TextDirection.ltr
    );
    tp.layout();
    return tp;
  }

  String format(double value) {
    if (dataFormat != null) return dataFormat!(value);

    final length = (data?.isEmpty ?? true) ? 2 : NumberUtil.getMaxDecimalLength(data!.first.open, data!.first.close, data!.first.high, data!.first.low);
    return value.toStringAsFixed(length);
  }

  String getDate(int? date) => dateFormat(DateTime.fromMillisecondsSinceEpoch(date ?? DateTime.now().millisecondsSinceEpoch), mFormats);

  double getMainY(double y) => mMainRenderer.getY(y);

  /// 点是否在SecondaryRect中
  bool isInSecondaryRect(Offset point) => mSecondaryRect?.contains(point) ?? false;

  /// 点是否在MainRect中
  bool isInMainRect(Offset point) => mMainRect.contains(point);
}
