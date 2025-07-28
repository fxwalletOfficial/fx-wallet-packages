#!/bin/bash

# Generate coverage data
echo "🧪 Running tests and generating coverage data..."
dart test --coverage=coverage

# Generate filtered LCOV report
echo "📊 Generating filtered LCOV report..."
dart run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov_filtered.info \
  --report-on=lib \
  --ignore-files="**/forked_lib/**"

# Generate filtered HTML report
echo "🌐 Generating filtered HTML report..."
genhtml coverage/lcov_filtered.info -o coverage/html_filtered

# Open filtered HTML report
echo "📈 Opening coverage report..."
open coverage/html_filtered/index.html

echo "✅ Coverage report generation completed!" 