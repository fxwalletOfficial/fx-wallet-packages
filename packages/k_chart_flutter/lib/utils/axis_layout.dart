import 'dart:math' as math;

/// How many of [rows] grid rows fit in [height] when each row holds two price
/// labels plus half a label of space.
///
/// The main chart draws the top price under the top grid line and every other
/// price above its own line, so the top two labels are the first to touch when
/// rows get short. Never returns more than [rows] or fewer than 1.
int fitGridRows(int rows, double height, double labelHeight) {
  if (rows < 1) return 1;
  if (!height.isFinite ||
      !labelHeight.isFinite ||
      height <= 0 ||
      labelHeight <= 0) return rows;
  return math.min(rows, math.max(1, (height / (labelHeight * 2.5)).floor()));
}

/// Round axis values between [min] and [max], one step of 1, 2 or 5 × 10ⁿ
/// apart.
///
/// The step is the smallest round number that is at least
/// `(max - min) / maxSteps`, so there are at most `maxSteps + 1` values.
/// Returns an empty list for an empty or non-finite range, or when the step is
/// too small for doubles to tell the values apart.
List<double> roundAxisTicks(double min, double max, int maxSteps) {
  if (!min.isFinite || !max.isFinite || max <= min || maxSteps < 1)
    return const [];
  final raw = (max - min) / maxSteps;
  final magnitude =
      math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  if (!magnitude.isFinite || magnitude <= 0) return const [];
  final step = [1, 2, 5, 10]
      .map((m) => m * magnitude)
      .firstWhere((s) => s >= raw * (1 - 1e-9));
  if (math.max(min.abs(), max.abs()) / step > 1e15) return const [];
  final first = (min / step).ceil();
  final last = (max / step).floor();
  // k * step leaves float noise such as 3.0000000000000004e-7; 12 significant digits drop it.
  return [
    for (var k = first; k <= last; k++)
      double.parse((k * step).toStringAsPrecision(12))
  ];
}
