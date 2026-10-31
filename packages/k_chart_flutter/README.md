# k_chart_flutter

A high-performance, interactive candlestick (K-line) and line chart widget for Flutter, designed for crypto and financial data visualization.

- Gesture support: drag, scale, long press, fling
- Main chart indicators: MA, BOLL
- Secondary indicators: MACD, KDJ, RSI, WR, CCI
- Customizable style and internationalization
- Suitable for crypto, stock, and other financial charts

## Installation

```yaml
dependencies:
  k_chart_flutter: ^1.0.0
```

## Quick Start

```dart
// Initialize data
data = DataUtil.calculate(data);

// Use the KChartWidget
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
    'en': ChartTranslations(
      date: 'Date',
      open: 'Open',
      high: 'High',
      low: 'Low',
      close: 'Close',
      changeAmount: 'Change',
      change: 'Change %',
      amount: 'Volume',
    )
  },
  showNowPrice: true,
  hideGrid: true,
  isTapShowInfoDialog: true,
  maDayList: const [1, 100, 1000],
  dataFormat: (value) => value.toStringAsFixed(2)
)
```

## Price axis

- The price axis, dates and max/min markers use `ChartStyle.dataFontSize`. The renderer styles' `fontSize` only sizes the indicator text (MA, BOLL, VOL, MACD…).
- On short charts the main chart draws fewer grid rows than `ChartStyle.gridRows`, so the top prices never overlap.
- `ChartStyle(roundYAxisTicks: true)` puts the main chart's grid lines and prices on round steps (1, 2 or 5 × 10ⁿ) instead of equal rows.
- `KChartWidget.xFrontPadding` is the empty room right of the newest candle (default 100). Pass `null` to size it to the widest price label the main chart can show plus 8px, at every zoom.

## Example

A full demo app is available at `examples/k_chart_demo` in this repository. You can run and debug it locally.

## Contributing

Issues and PRs are welcome!

## License

MIT
