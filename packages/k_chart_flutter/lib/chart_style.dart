import 'package:flutter/material.dart' show BorderRadius, Color, EdgeInsets;

String? DEFAULT_FONT_FAMILY = null;

class ChartColors {
  final List<Color> background;
  final Color defaultText;

  final Color nowPriceUp;
  final Color nowPriceDown;
  final Color nowPriceText;

  //当前显示内最大和最小值的颜色
  final Color maxColor;
  final Color minColor;

  const ChartColors({
    this.background = const [Color.fromARGB(255, 0, 0, 1), Color(0xff18191d)],
    this.defaultText = const Color(0xff60738E),

    this.nowPriceUp = const Color(0xff4DAA90),
    this.nowPriceDown = const Color(0xffC15466),
    this.nowPriceText = const Color(0xffffffff),

    this.maxColor = const Color(0xffffffff),
    this.minColor = const Color(0xffffffff)
  });
}

class RendererColors {
  /// Data up color.
  final Color up;

  /// Data down color.
  final Color down;

  /// Grid color.
  final Color grid;

  final Color ma5;
  final Color ma10;
  final Color ma30;

  const RendererColors({
    this.up = const Color(0xffC15466),
    this.down = const Color(0xff4DAA90),
    this.grid = const Color(0xff4c5c74),
    this.ma5 = const Color(0xffC9B885),
    this.ma10 = const Color(0xff6CB0A6),
    this.ma30 = const Color(0xff9979C6)
  });
}

class ChartStyle {
  //点与点的距离
  double pointWidth;

  //现在价格的线条长度
  double nowPriceLineLength;

  //现在价格的线条间隔
  double nowPriceLineSpan;

  //现在价格的线条粗细
  double nowPriceLineWidth;

  /// Chart number data text font size.
  final double dataFontSize;

  final String? fontFamily;

  int gridRows;

  int gridColumns;

  //下方時間客製化
  List<String>? dateTimeFormat;

  final MainRendererStyle main;
  final SecondaryRendererStyle secondary;
  final VolumeRendererStyle volume;

  final ChartSelectStyle select;

  final DepthColors depth;
  final ChartColors colors;

  ChartStyle({
    this.pointWidth = 11.0,
    this.nowPriceLineLength = 1,
    this.nowPriceLineSpan = 1,
    this.nowPriceLineWidth = 1,
    this.gridRows = 4,
    this.gridColumns = 4,
    this.dateTimeFormat,
    this.dataFontSize = 10,
    this.main = const MainRendererStyle(),
    this.secondary = const SecondaryRendererStyle(),
    this.volume = const VolumeRendererStyle(),
    this.select = const ChartSelectStyle(),
    this.depth = const DepthColors(),
    this.colors = const ChartColors(),
    this.fontFamily
  });
}

class RendererStyle {
  final double fontSize;
  final EdgeInsets padding;
  final RendererColors colors;

  const RendererStyle({
    this.fontSize = 10,
    this.padding = const EdgeInsets.only(left: 5, right: 5),
    this.colors = const RendererColors()
  });

  Color getMAColor(int index) {
    switch (index % 3) {
      case 1:
        return colors.ma10;
      case 2:
        return colors.ma30;
      default:
        return colors.ma5;
    }
  }
}

class MainRendererStyle extends RendererStyle {
  final double candleWidth;
  final double candleLineWidth;
  final VerticalTextAlignment yAxisAlignment;
  final MainRendererColors colors;

  const MainRendererStyle({
    this.candleWidth = 8.5,
    this.candleLineWidth = 1.5,
    this.yAxisAlignment = VerticalTextAlignment.left,
    this.colors = const MainRendererColors(),
    super.fontSize = 10,
    super.padding = const EdgeInsets.only(left: 5, right: 5, top: 22, bottom: 20)
  }) : super(colors: colors);
}

class MainRendererColors extends RendererColors {
  final Color kLine;
  final Color lineFill;
  final Color lineFillInside;

  const MainRendererColors({
    this.kLine = const Color(0xff4C86CD),
    this.lineFill = const Color(0x554C86CD),
    this.lineFillInside = const Color(0x00000000),

    super.up,
    super.down,
    super.grid,
    super.ma5,
    super.ma10,
    super.ma30
  });
}

class SecondaryRendererStyle extends RendererStyle {
  /// macd柱子宽度
  final double macdWidth;
  final SecondaryRendererColors colors;

  const SecondaryRendererStyle({
    this.macdWidth = 3.0,
    this.colors = const SecondaryRendererColors(),
    super.padding = const EdgeInsets.only(left: 5, right: 5, top: 12),
    super.fontSize = 10
  }) : super(colors: colors);
}

class SecondaryRendererColors extends RendererColors {
  final Color k;
  final Color d;
  final Color j;
  final Color rsi;
  final Color dif;
  final Color dea;
  final Color defaultText;
  final Color macd;

  const SecondaryRendererColors({
    this.macd = const Color(0xff4729AE),
    this.dif = const Color(0xffC9B885),
    this.dea = const Color(0xff6CB0A6),

    this.k = const Color(0xffC9B885),
    this.d = const Color(0xff6CB0A6),
    this.j = const Color(0xff9979C6),
    this.rsi = const Color(0xffC9B885),

    this.defaultText = const Color(0xff60738E),

    super.up,
    super.down,
    super.grid,
    super.ma5,
    super.ma10,
    super.ma30
  });
}

class VolumeRendererStyle extends RendererStyle {
  final double width;
  final VolumeRendererColors colors;

  const VolumeRendererStyle({
    this.width = 8.5,
    this.colors = const VolumeRendererColors(),
    super.padding = const EdgeInsets.only(left: 5, right: 5, top: 12),
    super.fontSize = 10
  }) : super(colors: colors);
}

class VolumeRendererColors extends RendererColors {
  final Color vol;

  const VolumeRendererColors({
    this.vol = const Color(0xff4729AE),

    super.up,
    super.down,
    super.grid,
    super.ma5,
    super.ma10,
    super.ma30
  });
}

class DepthColors {
  final Color buy;
  final Color sell;
  final Color selectFill;
  final Color selectBorder;

  const DepthColors({
    this.buy = const Color(0xff60A893),
    this.sell = const Color(0xffC15866),
    this.selectFill = const Color(0xff0D1722),
    this.selectBorder = const Color(0xff6C7A86)
  });
}

class ChartSelectStyle {
  /// Container border radius.
  final BorderRadius radius;

  /// Container padding.
  final EdgeInsets padding;

  /// Selected info container margin.
  /// - **Be careful！** It will auto show on right/left, so only left value will be used.
  /// - And also, bottom will never used.
  final EdgeInsets margin;

  /// Font size of every text in container.
  final double fontSize;

  /// Container width. If not set, will use screen width / 3.
  final double? width;

  final ChartSelectColors colors;

  /// Cross x line style when select dot.
  final ChartCrossLineStyle x;

  /// Cross y line style when select dot.
  final ChartCrossLineStyle y;

  final ChartCrossDotStyle dot;

  const ChartSelectStyle({
    this.radius = BorderRadius.zero,
    this.padding = const EdgeInsets.all(4),
    this.margin = const EdgeInsets.only(top: 25, left: 4),
    this.fontSize = 10,
    this.width,
    this.colors = const ChartSelectColors(),
    this.x = const ChartCrossLineStyle(),
    this.y = const ChartCrossLineStyle(),
    this.dot = const ChartCrossDotStyle()
  });
}

class ChartCrossLineStyle {
  /// Cross line width.
  final double width;

  /// Line span if draw dashed line. It will draw solid line if [span] or [length] not bigger than 0.
  final double span;

  /// Every length in dashed line. It will draw solid line if [span] or [length] not bigger than 0.
  final double length;

  /// Line color.
  final Color color;

  const ChartCrossLineStyle({
    this.width = 0.5,
    this.span = 5,
    this.length = 5,
    this.color = const Color(0xffffffff)
  });
}

class ChartCrossDotStyle {
  final double diameter;
  final Color color;

  const ChartCrossDotStyle({
    this.diameter = 5,
    this.color = const Color(0xffffffff)
  });
}

class ChartSelectColors {
  final Color fill;
  final Color border;
  final Color text;
  final Color upText;
  final Color downText;

  /// Selected dot color.
  final Color dot;

  const ChartSelectColors({
    this.fill = const Color(0xff0D1722),
    this.border = const Color(0xff6C7A86),
    this.text = const Color(0xffffffff),
    this.upText = const Color(0xffff0000),
    this.downText = const Color(0xff00ff00),
    this.dot = const Color(0xffffffff)
  });
}

enum VerticalTextAlignment {
  left,
  right
}

