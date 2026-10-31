## [0.1.0]

* NEW: Initial Release.

## [0.1.1]

* NEW: Update UI.

## [0.1.2]

* NEW: Remove ListView extents for detail dialog to adjust different screen size.

## [0.1.3]

- FEAT: Support FontFamily settings.

## [0.2.0]

- FIX: The main chart draws fewer grid rows when its rows are shorter than two price labels plus half a label, so the top two prices no longer overlap on short charts. Tall charts are unchanged.
- FEAT: `ChartStyle.roundYAxisTicks` (default `false`) puts the main chart's grid lines and prices on round steps (1, 2 or 5 × 10ⁿ).
- FEAT: `KChartWidget.xFrontPadding` accepts `null` to size the room right of the newest candle to the widest price label plus 8px. The default stays 100.
- DOCS: `ChartStyle.dataFontSize` drives the price axis; `RendererStyle.fontSize` only sizes the indicator text.
