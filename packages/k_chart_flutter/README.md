# k_chart_flutter
K chart widget in Flutter.

- Support gesture **drag**, **scale**, **long press**, **fling**.
- Support **MA**, **BOLL** for main chart.
- Support **MACD**, **KDJ**, **RSI**, **WR**, **CCI** for secondary chart.

## Getting Started
### Install
```
dependencies:
  k_chart_flutter: ^1.0.0
```

### Usage

```dart
// Init data.
DataUtil.calculate(data);

// Use k chart widget:
KChartWidget(
  data: data,
  style: ChartStyle(),
  isLine: true,
  isTrendLine: false,
  mainState: MainState.MA,
  volHidden: false,
  secondaryState: SecondaryState.MACD,
  timeFormat: TimeFormat.YEAR_MONTH_DAY,
  translations: {
    'zh_CN': ChartTranslations(
      date: '时间',
      open: '开',
      high: '高',
      low: '低',
      close: '收',
      changeAmount: '涨跌额',
      change: '涨跌幅',
      amount: '成交额',
    )
  },
  showNowPrice: true,
  hideGrid: true,
  isTapShowInfoDialog: true,
  maDayList: const [1, 100, 1000],
  dataFormat: (value) => value.toStringAsFixed(2)
)
```
