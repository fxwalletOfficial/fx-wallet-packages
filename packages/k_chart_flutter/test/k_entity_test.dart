import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart_flutter/entity/k_entity.dart';

void main() {
  group('KEntity Tests', () {
    test('should create KEntity instance', () {
      final entity = KEntity();
      expect(entity, isNotNull);
      expect(entity, isA<KEntity>());
    });

    test('should be able to access basic properties', () {
      final entity = KEntity();

      // Test that we can access basic properties without errors
      expect(() {
        // This test verifies that the entity can be used without errors
        entity.toString();
      }, returnsNormally);
    });

    test('should be able to set and get candle properties', () {
      final entity = KEntity();

      // Test setting candle properties
      entity.open = 100.0;
      entity.high = 110.0;
      entity.low = 90.0;
      entity.close = 105.0;

      expect(entity.open, equals(100.0));
      expect(entity.high, equals(110.0));
      expect(entity.low, equals(90.0));
      expect(entity.close, equals(105.0));
    });
  });
}