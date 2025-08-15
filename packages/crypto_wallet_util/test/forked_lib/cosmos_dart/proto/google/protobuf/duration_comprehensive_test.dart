import 'dart:convert';

import 'package:test/test.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/google/protobuf/duration.pb.dart';

void main() {
	group('google.protobuf Duration', () {
		test('constructor with all parameters', () {
			final duration = Duration(
				seconds: Int64(3661), // 1 hour, 1 minute, 1 second
				nanos: 123456789,
			);
			
			expect(duration.seconds, Int64(3661));
			expect(duration.nanos, 123456789);
		});
		
		test('constructor with partial parameters', () {
			final duration = Duration(seconds: Int64(300)); // 5 minutes
			
			expect(duration.seconds, Int64(300));
			expect(duration.nanos, 0);
		});
		
		test('default constructor', () {
			final duration = Duration();
			
			expect(duration.seconds, Int64.ZERO);
			expect(duration.nanos, 0);
		});
		
		test('has/clear operations for seconds', () {
			final duration = Duration(seconds: Int64(86400)); // 1 day
			
			expect(duration.hasSeconds(), true);
			expect(duration.seconds, Int64(86400));
			
			duration.clearSeconds();
			expect(duration.hasSeconds(), false);
			expect(duration.seconds, Int64.ZERO);
		});
		
		test('has/clear operations for nanos', () {
			final duration = Duration(nanos: 500000000); // 0.5 seconds
			
			expect(duration.hasNanos(), true);
			expect(duration.nanos, 500000000);
			
			duration.clearNanos();
			expect(duration.hasNanos(), false);
			expect(duration.nanos, 0);
		});
		
		test('setting and getting values', () {
			final duration = Duration();
			
			duration.seconds = Int64(7200); // 2 hours
			duration.nanos = 250000000; // 0.25 seconds
			
			expect(duration.seconds, Int64(7200));
			expect(duration.nanos, 250000000);
		});
		
		test('clone operation', () {
			final original = Duration(
				seconds: Int64(1800), // 30 minutes
				nanos: 750000000,
			);
			
			final cloned = original.clone();
			expect(cloned.seconds, Int64(1800));
			expect(cloned.nanos, 750000000);
			
			// Verify independence
			cloned.seconds = Int64(3600);
			cloned.nanos = 999999999;
			
			expect(cloned.seconds, Int64(3600));
			expect(cloned.nanos, 999999999);
			expect(original.seconds, Int64(1800));
			expect(original.nanos, 750000000);
		});
		
		test('copyWith operation', () {
			final original = Duration(
				seconds: Int64(60), // 1 minute
				nanos: 123456789,
			);
			
			final copied = original.clone().copyWith((duration) {
				duration.seconds = Int64(120); // 2 minutes
				duration.nanos = 987654321;
			});
			
			expect(copied.seconds, Int64(120));
			expect(copied.nanos, 987654321);
			expect(original.seconds, Int64(60)); // original unchanged
			expect(original.nanos, 123456789);
		});
		
		test('JSON serialization and deserialization', () {
			final duration = Duration(
				seconds: Int64(3600), // 1 hour
				nanos: 500000000,
			);
			
			final json = jsonEncode(duration.writeToJsonMap());
			final fromJson = Duration.fromJson(json);
			
			expect(fromJson.seconds, Int64(3600));
			expect(fromJson.nanos, 500000000);
		});
		
		test('binary serialization and deserialization', () {
			final duration = Duration(
				seconds: Int64(43200), // 12 hours
				nanos: 750000000,
			);
			
			final buffer = duration.writeToBuffer();
			final fromBuffer = Duration.fromBuffer(buffer);
			
			expect(fromBuffer.seconds, Int64(43200));
			expect(fromBuffer.nanos, 750000000);
		});
		
		test('getDefault returns same instance', () {
			final default1 = Duration.getDefault();
			final default2 = Duration.getDefault();
			expect(identical(default1, default2), isTrue);
		});
		
		test('createEmptyInstance creates new instance', () {
			final duration = Duration();
			final empty = duration.createEmptyInstance();
			expect(empty.seconds, Int64.ZERO);
			expect(empty.nanos, 0);
			expect(identical(duration, empty), isFalse);
		});
		
		test('createRepeated creates PbList', () {
			final list = Duration.createRepeated();
			expect(list, isA<pb.PbList<Duration>>());
			expect(list, isEmpty);
			
			list.add(Duration(seconds: Int64(30)));
			expect(list.length, 1);
		});
		
		test('info_ returns BuilderInfo', () {
			final duration = Duration();
			final info = duration.info_;
			expect(info, isA<pb.BuilderInfo>());
			expect(info.qualifiedMessageName, contains('Duration'));
		});
		
		test('zero duration', () {
			final duration = Duration(seconds: Int64.ZERO, nanos: 0);
			
			expect(duration.seconds, Int64.ZERO);
			expect(duration.nanos, 0);
			
			final buffer = duration.writeToBuffer();
			final restored = Duration.fromBuffer(buffer);
			expect(restored.seconds, Int64.ZERO);
			expect(restored.nanos, 0);
		});
		
		test('maximum duration values', () {
			final duration = Duration(
				seconds: Int64.parseInt('9223372036854775807'), // Max Int64
				nanos: 999999999, // Max nanoseconds (< 1 second)
			);
			
			expect(duration.seconds.toString(), '9223372036854775807');
			expect(duration.nanos, 999999999);
			
			final buffer = duration.writeToBuffer();
			final restored = Duration.fromBuffer(buffer);
			expect(restored.seconds.toString(), '9223372036854775807');
			expect(restored.nanos, 999999999);
		});
		
		test('negative duration', () {
			// Test negative durations
			final duration = Duration(
				seconds: Int64(-3600), // -1 hour
				nanos: -500000000, // -0.5 seconds
			);
			
			expect(duration.seconds, Int64(-3600));
			expect(duration.nanos, -500000000);
			
			final buffer = duration.writeToBuffer();
			final restored = Duration.fromBuffer(buffer);
			expect(restored.seconds, Int64(-3600));
			expect(restored.nanos, -500000000);
		});
		
		test('various time durations', () {
			final testDurations = [
				{'name': 'Millisecond', 'seconds': 0, 'nanos': 1000000},
				{'name': 'Second', 'seconds': 1, 'nanos': 0},
				{'name': 'Minute', 'seconds': 60, 'nanos': 0},
				{'name': 'Hour', 'seconds': 3600, 'nanos': 0},
				{'name': 'Day', 'seconds': 86400, 'nanos': 0},
				{'name': 'Week', 'seconds': 604800, 'nanos': 0},
				{'name': 'Month (30 days)', 'seconds': 2592000, 'nanos': 0},
				{'name': 'Year (365 days)', 'seconds': 31536000, 'nanos': 0},
			];
			
			for (final test in testDurations) {
				final duration = Duration(
					seconds: Int64(test['seconds'] as int),
					nanos: test['nanos'] as int,
				);
				
				expect(duration.seconds, Int64(test['seconds'] as int));
				expect(duration.nanos, test['nanos'] as int);
				
				final buffer = duration.writeToBuffer();
				final restored = Duration.fromBuffer(buffer);
				expect(restored.seconds, duration.seconds, 
					reason: 'Failed for ${test['name']}');
				expect(restored.nanos, duration.nanos, 
					reason: 'Failed for ${test['name']}');
			}
		});
		
		test('fractional seconds with nanoseconds', () {
			final fractionalTests = [
				{'desc': '0.1 seconds', 'nanos': 100000000},
				{'desc': '0.25 seconds', 'nanos': 250000000},
				{'desc': '0.5 seconds', 'nanos': 500000000},
				{'desc': '0.75 seconds', 'nanos': 750000000},
				{'desc': '0.999999999 seconds', 'nanos': 999999999},
			];
			
			for (final test in fractionalTests) {
				final duration = Duration(
					seconds: Int64(5), // 5 seconds base
					nanos: test['nanos'] as int,
				);
				
				expect(duration.nanos, test['nanos'] as int);
				
				final buffer = duration.writeToBuffer();
				final restored = Duration.fromBuffer(buffer);
				expect(restored.nanos, test['nanos'] as int, 
					reason: 'Failed for ${test['desc']}');
			}
		});
		
		test('duration mixin functionality', () {
			// Test that Duration has DurationMixin functionality
			final duration = Duration(
				seconds: Int64(3661), // 1:01:01
				nanos: 123456789,
			);
			
			// The mixin should provide additional functionality
			// We test what we can verify without accessing private mixin methods
			expect(duration, isA<Duration>());
			
			// Test JSON behavior which should use the mixin
			final json = jsonEncode(duration.writeToJsonMap());
			expect(json, isA<String>());
			
			final fromJson = Duration.fromJson(json);
			expect(fromJson.seconds, Int64(3661));
			expect(fromJson.nanos, 123456789);
		});
		
		test('well-known type JSON behavior', () {
			// Test that Duration behaves as a well-known type with special JSON handling
			final duration = Duration(
				seconds: Int64(125), // 2 minutes 5 seconds
				nanos: 250000000, // 0.25 seconds
			);
			
			// The Duration should handle JSON serialization with DurationMixin
			final json = jsonEncode(duration.writeToJsonMap());
			expect(json, isA<String>());
			
			final fromJson = Duration.fromJson(json);
			expect(fromJson.seconds, Int64(125));
			expect(fromJson.nanos, 250000000);
		});
		
		test('precision edge cases', () {
			final precisionTests = [
				{'desc': 'Nanosecond precision', 'nanos': 1},
				{'desc': 'Microsecond precision', 'nanos': 1000},
				{'desc': 'Millisecond precision', 'nanos': 1000000},
				{'desc': 'Centisecond precision', 'nanos': 10000000},
				{'desc': 'Decisecond precision', 'nanos': 100000000},
			];
			
			for (final test in precisionTests) {
				final duration = Duration(
					seconds: Int64(0),
					nanos: test['nanos'] as int,
				);
				
				expect(duration.nanos, test['nanos'] as int);
				
				final buffer = duration.writeToBuffer();
				final restored = Duration.fromBuffer(buffer);
				expect(restored.nanos, test['nanos'] as int, 
					reason: 'Failed for ${test['desc']}');
			}
		});
		
		test('large time scales', () {
			final largeScaleTests = [
				{'desc': 'Century', 'seconds': 3153600000}, // 100 years
				{'desc': 'Millennium', 'seconds': 31536000000}, // 1000 years
				{'desc': 'Geological time', 'seconds': 31536000000000}, // 1 million years
			];
			
			for (final test in largeScaleTests) {
				final duration = Duration(
					seconds: Int64(test['seconds'] as int),
					nanos: 0,
				);
				
				expect(duration.seconds, Int64(test['seconds'] as int));
				
				final buffer = duration.writeToBuffer();
				final restored = Duration.fromBuffer(buffer);
				expect(restored.seconds, Int64(test['seconds'] as int), 
					reason: 'Failed for ${test['desc']}');
			}
		});
		
		test('negative duration edge cases', () {
			final negativeTests = [
				{'desc': 'Negative millisecond', 'seconds': 0, 'nanos': -1000000},
				{'desc': 'Negative second', 'seconds': -1, 'nanos': 0},
				{'desc': 'Negative minute', 'seconds': -60, 'nanos': 0},
				{'desc': 'Negative hour', 'seconds': -3600, 'nanos': 0},
				{'desc': 'Mixed negative', 'seconds': -1, 'nanos': -500000000},
			];
			
			for (final test in negativeTests) {
				final duration = Duration(
					seconds: Int64(test['seconds'] as int),
					nanos: test['nanos'] as int,
				);
				
				expect(duration.seconds, Int64(test['seconds'] as int));
				expect(duration.nanos, test['nanos'] as int);
				
				final buffer = duration.writeToBuffer();
				final restored = Duration.fromBuffer(buffer);
				expect(restored.seconds, Int64(test['seconds'] as int), 
					reason: 'Failed for ${test['desc']}');
				expect(restored.nanos, test['nanos'] as int, 
					reason: 'Failed for ${test['desc']}');
			}
		});
		
		test('boundary nanosecond values', () {
			final boundaryTests = [
				0,           // Zero
				1,           // Minimum positive
				-1,          // Minimum negative
				999999999,   // Maximum positive (< 1 second)
				-999999999,  // Maximum negative (> -1 second)
			];
			
			for (final nanos in boundaryTests) {
				final duration = Duration(
					seconds: Int64(10),
					nanos: nanos,
				);
				
				expect(duration.nanos, nanos);
				
				final buffer = duration.writeToBuffer();
				final restored = Duration.fromBuffer(buffer);
				expect(restored.nanos, nanos, 
					reason: 'Failed for nanos=$nanos');
			}
		});
	});
	
	group('google.protobuf Duration error handling', () {
		test('invalid buffer deserialization', () {
			expect(() => Duration.fromBuffer([0xFF, 0xFF, 0xFF]), 
				throwsA(isA<pb.InvalidProtocolBufferException>()));
		});
		
		test('invalid JSON deserialization', () {
			expect(() => Duration.fromJson('invalid json'), 
				throwsA(isA<FormatException>()));
		});
	});
	
	group('google.protobuf Duration comprehensive coverage', () {
		test('message type has proper info_', () {
			expect(Duration().info_, isA<pb.BuilderInfo>());
		});
		
		test('message type supports createEmptyInstance', () {
			expect(Duration().createEmptyInstance(), isA<Duration>());
		});
		
		test('getDefault returns same instance', () {
			expect(identical(Duration.getDefault(), Duration.getDefault()), isTrue);
		});
		
		test('complete duration workflow', () {
			// Test a complete workflow of creating, serializing, and deserializing durations
			
			// 1. Create complex duration (2 hours, 15 minutes, 30.75 seconds)
			final originalDuration = Duration(
				seconds: Int64(8130), // 2*3600 + 15*60 + 30 = 8130
				nanos: 750000000, // 0.75 seconds
			);
			
			expect(originalDuration.seconds, Int64(8130));
			expect(originalDuration.nanos, 750000000);
			
			// 2. Test JSON serialization
			final json = jsonEncode(originalDuration.writeToJsonMap());
			expect(json, isA<String>());
			
			// 3. Deserialize from JSON
			final fromJson = Duration.fromJson(json);
			expect(fromJson.seconds, originalDuration.seconds);
			expect(fromJson.nanos, originalDuration.nanos);
			
			// 4. Test binary serialization
			final buffer = originalDuration.writeToBuffer();
			expect(buffer, isA<List<int>>());
			
			// 5. Deserialize from binary
			final fromBuffer = Duration.fromBuffer(buffer);
			expect(fromBuffer.seconds, originalDuration.seconds);
			expect(fromBuffer.nanos, originalDuration.nanos);
			
			// 6. Test cloning
			final cloned = fromBuffer.clone();
			expect(cloned.seconds, originalDuration.seconds);
			expect(cloned.nanos, originalDuration.nanos);
			
			// 7. Verify independence
			cloned.seconds = Int64(1800); // 30 minutes
			cloned.nanos = 500000000; // 0.5 seconds
			
			expect(cloned.seconds, Int64(1800));
			expect(cloned.nanos, 500000000);
			expect(fromBuffer.seconds, Int64(8130)); // Original unchanged
			expect(fromBuffer.nanos, 750000000);
		});
		
		test('field presence and default behavior', () {
			final duration = Duration();
			
			// Test initial state (no fields set)
			expect(duration.hasSeconds(), false);
			expect(duration.hasNanos(), false);
			
			// Test default values
			expect(duration.seconds, Int64.ZERO);
			expect(duration.nanos, 0);
			
			// Set fields and verify presence
			duration.seconds = Int64(300);
			duration.nanos = 123456789;
			
			expect(duration.hasSeconds(), true);
			expect(duration.hasNanos(), true);
			
			// Clear fields and verify absence
			duration.clearSeconds();
			duration.clearNanos();
			
			expect(duration.hasSeconds(), false);
			expect(duration.hasNanos(), false);
			expect(duration.seconds, Int64.ZERO);
			expect(duration.nanos, 0);
		});
		
		test('seconds boundary conditions', () {
			final secondsTests = [
				Int64.ZERO,                              // Zero duration
				Int64(1),                               // 1 second
				Int64(-1),                              // -1 second
				Int64(86400),                           // 1 day
				Int64(-86400),                          // -1 day
				Int64(2147483647),                      // 32-bit max
				Int64(-2147483648),                     // 32-bit min
				Int64.parseInt('9223372036854775807'),  // 64-bit max
			];
			
			for (final seconds in secondsTests) {
				final duration = Duration(
					seconds: seconds,
					nanos: 123456789,
				);
				
				expect(duration.seconds, seconds);
				
				final buffer = duration.writeToBuffer();
				final fromBuffer = Duration.fromBuffer(buffer);
				expect(fromBuffer.seconds, seconds);
				expect(fromBuffer.nanos, 123456789);
			}
		});
		
		test('common duration patterns', () {
			// Test common duration patterns used in applications
			final commonDurations = [
				{'name': 'HTTP timeout', 'seconds': 30, 'nanos': 0},
				{'name': 'Database timeout', 'seconds': 300, 'nanos': 0}, // 5 minutes
				{'name': 'Cache TTL', 'seconds': 3600, 'nanos': 0}, // 1 hour
				{'name': 'Session timeout', 'seconds': 1800, 'nanos': 0}, // 30 minutes
				{'name': 'Retry backoff', 'seconds': 0, 'nanos': 500000000}, // 0.5 seconds
				{'name': 'Polling interval', 'seconds': 5, 'nanos': 0},
				{'name': 'Animation duration', 'seconds': 0, 'nanos': 250000000}, // 0.25 seconds
			];
			
			for (final pattern in commonDurations) {
				final duration = Duration(
					seconds: Int64(pattern['seconds'] as int),
					nanos: pattern['nanos'] as int,
				);
				
				expect(duration.seconds, Int64(pattern['seconds'] as int));
				expect(duration.nanos, pattern['nanos'] as int);
				
				// Test serialization roundtrip
				final json = jsonEncode(duration.writeToJsonMap());
				final fromJson = Duration.fromJson(json);
				expect(fromJson.seconds, duration.seconds, 
					reason: 'JSON failed for ${pattern['name']}');
				expect(fromJson.nanos, duration.nanos, 
					reason: 'JSON failed for ${pattern['name']}');
				
				final buffer = duration.writeToBuffer();
				final fromBuffer = Duration.fromBuffer(buffer);
				expect(fromBuffer.seconds, duration.seconds, 
					reason: 'Buffer failed for ${pattern['name']}');
				expect(fromBuffer.nanos, duration.nanos, 
					reason: 'Buffer failed for ${pattern['name']}');
			}
		});
		
		test('duration arithmetic edge cases', () {
			// Test edge cases that might occur in duration arithmetic
			final arithmeticTests = [
				{'desc': 'Almost 1 second', 'seconds': 0, 'nanos': 999999999},
				{'desc': 'Just over 1 second', 'seconds': 1, 'nanos': 1},
				{'desc': 'Negative almost 1 second', 'seconds': 0, 'nanos': -999999999},
				{'desc': 'Negative just over 1 second', 'seconds': -1, 'nanos': -1},
				{'desc': 'Mixed sign 1', 'seconds': 1, 'nanos': -500000000}, // 0.5 seconds
				{'desc': 'Mixed sign 2', 'seconds': -1, 'nanos': 500000000}, // -0.5 seconds
			];
			
			for (final test in arithmeticTests) {
				final duration = Duration(
					seconds: Int64(test['seconds'] as int),
					nanos: test['nanos'] as int,
				);
				
				expect(duration.seconds, Int64(test['seconds'] as int));
				expect(duration.nanos, test['nanos'] as int);
				
				final buffer = duration.writeToBuffer();
				final restored = Duration.fromBuffer(buffer);
				expect(restored.seconds, Int64(test['seconds'] as int), 
					reason: 'Failed for ${test['desc']}');
				expect(restored.nanos, test['nanos'] as int, 
					reason: 'Failed for ${test['desc']}');
			}
		});
	});
} 