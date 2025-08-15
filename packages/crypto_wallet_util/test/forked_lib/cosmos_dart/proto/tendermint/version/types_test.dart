import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/proto/tendermint/version/types.pb.dart';

void main() {
  group('App Tests', () {
    test('should create empty App', () {
      final app = App();
      
      expect(app.hasProtocol(), false);
      expect(app.hasSoftware(), false);
      expect(app.protocol, Int64.ZERO); // Default value
      expect(app.software, ''); // Default empty string
    });

    test('should create App with protocol and software', () {
      final app = App(
        protocol: Int64(1),
        software: 'tendermint v0.34.0',
      );
      
      expect(app.hasProtocol(), true);
      expect(app.hasSoftware(), true);
      expect(app.protocol, Int64(1));
      expect(app.software, 'tendermint v0.34.0');
    });

    test('should set and get App fields individually', () {
      final app = App();
      
      // Set protocol
      app.protocol = Int64(10);
      expect(app.hasProtocol(), true);
      expect(app.protocol, Int64(10));
      
      // Set software
      app.software = 'cosmos-sdk v0.44.0';
      expect(app.hasSoftware(), true);
      expect(app.software, 'cosmos-sdk v0.44.0');
    });

    test('should clear App fields', () {
      final app = App(
        protocol: Int64(5),
        software: 'test-software v1.0.0',
      );
      
      // Clear fields
      app.clearProtocol();
      app.clearSoftware();
      
      expect(app.hasProtocol(), false);
      expect(app.hasSoftware(), false);
      expect(app.protocol, Int64.ZERO); // Returns to default
      expect(app.software, ''); // Returns to default
    });

    test('should handle different protocol versions', () {
      final protocols = [Int64.ZERO, Int64.ONE, Int64(100), Int64(9999), Int64.MAX_VALUE];
      
      for (final protocol in protocols) {
        final app = App(protocol: protocol);
        expect(app.protocol, protocol);
        expect(app.hasProtocol(), true); // Setting any value makes hasProtocol() return true
      }
    });

    test('should handle various software version strings', () {
      final softwareVersions = [
        '',
        'v1.0.0',
        'tendermint v0.34.21',
        'cosmos-sdk v0.44.5',
        'gaia v7.0.0',
        'osmosis v10.0.0-beta1',
        'juno v8.0.0+abc123',
        'app with spaces v1.2.3',
        '特殊字符版本 v1.0.0', // Unicode characters
        'very-long-software-name-with-many-components-and-version-numbers v1.2.3-beta.4+build.567',
      ];
      
      for (final software in softwareVersions) {
        final app = App(software: software);
        expect(app.software, software);
        expect(app.hasSoftware(), true); // Setting any value makes hasSoftware() return true
      }
    });

    test('should clone App correctly', () {
      final original = App(
        protocol: Int64(42),
        software: 'original-app v2.1.0',
      );
      
      final cloned = original.clone();
      
      expect(cloned.protocol, original.protocol);
      expect(cloned.software, original.software);
      expect(cloned.hasProtocol(), original.hasProtocol());
      expect(cloned.hasSoftware(), original.hasSoftware());
    });

    test('should serialize App to and from buffer', () {
      final original = App(
        protocol: Int64(123456),
        software: 'serialization-test v3.2.1',
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = App.fromBuffer(buffer);
      
      expect(deserialized.protocol, original.protocol);
      expect(deserialized.software, original.software);
      expect(deserialized.hasProtocol(), original.hasProtocol());
      expect(deserialized.hasSoftware(), original.hasSoftware());
    });

    test('should serialize App to and from JSON', () {
      final original = App(
        protocol: Int64(789),
        software: 'json-test v4.0.0-rc1',
      );
      
      final json = original.writeToJson();
      final deserialized = App.fromJson(json);
      
      expect(deserialized.protocol, original.protocol);
      expect(deserialized.software, original.software);
      expect(deserialized.hasProtocol(), original.hasProtocol());
      expect(deserialized.hasSoftware(), original.hasSoftware());
    });

    test('should handle copyWith correctly', () {
      final original = App(
        protocol: Int64(1),
        software: 'original v1.0.0',
      );
      
      final modified = original.copyWith((app) {
        app.protocol = Int64(2);
        app.software = 'modified v2.0.0';
      });
      
      expect(modified.protocol, Int64(2));
      expect(modified.software, 'modified v2.0.0');
      expect(modified.hasProtocol(), true);
      expect(modified.hasSoftware(), true);
    });

    test('should return correct default instance', () {
      final defaultInstance = App.getDefault();
      
      expect(defaultInstance, isNotNull);
      expect(defaultInstance.hasProtocol(), false);
      expect(defaultInstance.hasSoftware(), false);
      expect(defaultInstance.protocol, Int64.ZERO);
      expect(defaultInstance.software, '');
    });

    test('should create repeated list', () {
      final list = App.createRepeated();
      
      expect(list, isNotNull);
      expect(list.isEmpty, true);
      
      list.add(App(protocol: Int64(1), software: 'app1 v1.0.0'));
      list.add(App(protocol: Int64(2), software: 'app2 v2.0.0'));
      
      expect(list.length, 2);
      expect(list[0].protocol, Int64(1));
      expect(list[1].software, 'app2 v2.0.0');
    });

    test('should handle edge cases', () {
      // Test with only protocol set
      final protocolOnly = App(protocol: Int64(999));
      expect(protocolOnly.hasProtocol(), true);
      expect(protocolOnly.hasSoftware(), false);
      expect(protocolOnly.software, ''); // Default value
      
      // Test with only software set
      final softwareOnly = App(software: 'software-only v1.0.0');
      expect(softwareOnly.hasProtocol(), false);
      expect(softwareOnly.hasSoftware(), true);
      expect(softwareOnly.protocol, Int64.ZERO); // Default value
      
      // Test clearing and resetting
      final app = App(protocol: Int64(100), software: 'test v1.0.0');
      app.clearProtocol();
      app.protocol = Int64(200);
      expect(app.protocol, Int64(200));
    });
  });

  group('Consensus Tests', () {
    test('should create empty Consensus', () {
      final consensus = Consensus();
      
      expect(consensus.hasBlock(), false);
      expect(consensus.hasApp(), false);
      expect(consensus.block, Int64.ZERO); // Default value
      expect(consensus.app, Int64.ZERO); // Default value
    });

    test('should create Consensus with block and app versions', () {
      final consensus = Consensus(
        block: Int64(11),
        app: Int64(1),
      );
      
      expect(consensus.hasBlock(), true);
      expect(consensus.hasApp(), true);
      expect(consensus.block, Int64(11));
      expect(consensus.app, Int64(1));
    });

    test('should set and get Consensus fields individually', () {
      final consensus = Consensus();
      
      // Set block version
      consensus.block = Int64(20);
      expect(consensus.hasBlock(), true);
      expect(consensus.block, Int64(20));
      
      // Set app version
      consensus.app = Int64(5);
      expect(consensus.hasApp(), true);
      expect(consensus.app, Int64(5));
    });

    test('should clear Consensus fields', () {
      final consensus = Consensus(
        block: Int64(15),
        app: Int64(3),
      );
      
      // Clear fields
      consensus.clearBlock();
      consensus.clearApp();
      
      expect(consensus.hasBlock(), false);
      expect(consensus.hasApp(), false);
      expect(consensus.block, Int64.ZERO); // Returns to default
      expect(consensus.app, Int64.ZERO); // Returns to default
    });

    test('should handle different version combinations', () {
      final testCases = [
        {'block': Int64.ZERO, 'app': Int64.ZERO},
        {'block': Int64.ONE, 'app': Int64.ZERO},
        {'block': Int64.ZERO, 'app': Int64.ONE},
        {'block': Int64(11), 'app': Int64(1)}, // Tendermint standard
        {'block': Int64(10), 'app': Int64(0)}, // Older version
        {'block': Int64(12), 'app': Int64(2)}, // Newer version
        {'block': Int64(999), 'app': Int64(888)}, // High version numbers
      ];
      
      for (final testCase in testCases) {
        final consensus = Consensus(
          block: testCase['block'] as Int64,
          app: testCase['app'] as Int64,
        );
        
        expect(consensus.block, testCase['block']);
        expect(consensus.app, testCase['app']);
        expect(consensus.hasBlock(), true); // Setting any value makes hasBlock() return true
        expect(consensus.hasApp(), true); // Setting any value makes hasApp() return true
      }
    });

    test('should clone Consensus correctly', () {
      final original = Consensus(
        block: Int64(33),
        app: Int64(7),
      );
      
      final cloned = original.clone();
      
      expect(cloned.block, original.block);
      expect(cloned.app, original.app);
      expect(cloned.hasBlock(), original.hasBlock());
      expect(cloned.hasApp(), original.hasApp());
    });

    test('should serialize Consensus to and from buffer', () {
      final original = Consensus(
        block: Int64(98765),
        app: Int64(43210),
      );
      
      final buffer = original.writeToBuffer();
      final deserialized = Consensus.fromBuffer(buffer);
      
      expect(deserialized.block, original.block);
      expect(deserialized.app, original.app);
      expect(deserialized.hasBlock(), original.hasBlock());
      expect(deserialized.hasApp(), original.hasApp());
    });

    test('should serialize Consensus to and from JSON', () {
      final original = Consensus(
        block: Int64(555),
        app: Int64(777),
      );
      
      final json = original.writeToJson();
      final deserialized = Consensus.fromJson(json);
      
      expect(deserialized.block, original.block);
      expect(deserialized.app, original.app);
      expect(deserialized.hasBlock(), original.hasBlock());
      expect(deserialized.hasApp(), original.hasApp());
    });

    test('should handle copyWith correctly', () {
      final original = Consensus(
        block: Int64(10),
        app: Int64(1),
      );
      
      final modified = original.copyWith((consensus) {
        consensus.block = Int64(11);
        consensus.app = Int64(2);
      });
      
      expect(modified.block, Int64(11));
      expect(modified.app, Int64(2));
      expect(modified.hasBlock(), true);
      expect(modified.hasApp(), true);
    });

    test('should return correct default instance', () {
      final defaultInstance = Consensus.getDefault();
      
      expect(defaultInstance, isNotNull);
      expect(defaultInstance.hasBlock(), false);
      expect(defaultInstance.hasApp(), false);
      expect(defaultInstance.block, Int64.ZERO);
      expect(defaultInstance.app, Int64.ZERO);
    });

    test('should create repeated list', () {
      final list = Consensus.createRepeated();
      
      expect(list, isNotNull);
      expect(list.isEmpty, true);
      
      list.add(Consensus(block: Int64(11), app: Int64(1)));
      list.add(Consensus(block: Int64(12), app: Int64(2)));
      
      expect(list.length, 2);
      expect(list[0].block, Int64(11));
      expect(list[1].app, Int64(2));
    });

    test('should handle version compatibility scenarios', () {
      // Test common Tendermint version combinations
      final compatibleVersions = [
        Consensus(block: Int64(10), app: Int64(0)), // Tendermint v0.33.x
        Consensus(block: Int64(11), app: Int64(0)), // Tendermint v0.34.x
        Consensus(block: Int64(11), app: Int64(1)), // Cosmos SDK integration
      ];
      
      for (int i = 0; i < compatibleVersions.length; i++) {
        final version = compatibleVersions[i];
        expect(version.block >= Int64(10), true, reason: 'Block version should be at least 10');
        expect(version.app >= Int64.ZERO, true, reason: 'App version should be non-negative');
      }
    });

    test('should handle edge cases', () {
      // Test with only block version set
      final blockOnly = Consensus(block: Int64(15));
      expect(blockOnly.hasBlock(), true);
      expect(blockOnly.hasApp(), false);
      expect(blockOnly.app, Int64.ZERO); // Default value
      
      // Test with only app version set
      final appOnly = Consensus(app: Int64(5));
      expect(appOnly.hasBlock(), false);
      expect(appOnly.hasApp(), true);
      expect(appOnly.block, Int64.ZERO); // Default value
      
      // Test clearing and resetting
      final consensus = Consensus(block: Int64(20), app: Int64(10));
      consensus.clearBlock();
      consensus.block = Int64(25);
      expect(consensus.block, Int64(25));
    });
  });

  group('Integration Tests', () {
    test('should handle App and Consensus together in version context', () {
      // Simulate a complete version specification
      final appVersion = App(
        protocol: Int64(1),
        software: 'cosmos-hub v7.0.0',
      );
      
      final consensusVersion = Consensus(
        block: Int64(11),
        app: Int64(1),
      );
      
      // Verify compatibility
      expect(appVersion.protocol, consensusVersion.app);
      
      // Test serialization of both
      final appBuffer = appVersion.writeToBuffer();
      final consensusBuffer = consensusVersion.writeToBuffer();
      
      final deserializedApp = App.fromBuffer(appBuffer);
      final deserializedConsensus = Consensus.fromBuffer(consensusBuffer);
      
      expect(deserializedApp.protocol, appVersion.protocol);
      expect(deserializedApp.software, appVersion.software);
      expect(deserializedConsensus.block, consensusVersion.block);
      expect(deserializedConsensus.app, consensusVersion.app);
    });

    test('should handle version upgrade scenarios', () {
      // Simulate version upgrade from v0.34 to v0.37
      final oldConsensus = Consensus(block: Int64(11), app: Int64(0));
      final newConsensus = Consensus(block: Int64(11), app: Int64(1));
      
      final oldApp = App(protocol: Int64(0), software: 'tendermint v0.34.21');
      final newApp = App(protocol: Int64(1), software: 'tendermint v0.37.0');
      
      // Verify upgrade path
      expect(newConsensus.block >= oldConsensus.block, true);
      expect(newConsensus.app >= oldConsensus.app, true);
      expect(newApp.protocol >= oldApp.protocol, true);
    });

    test('should handle maximum values correctly', () {
      final maxApp = App(
        protocol: Int64.MAX_VALUE,
        software: 'max-version-software v999.999.999',
      );
      
      final maxConsensus = Consensus(
        block: Int64.MAX_VALUE,
        app: Int64.MAX_VALUE,
      );
      
      // Test serialization with max values
      final appBuffer = maxApp.writeToBuffer();
      final consensusBuffer = maxConsensus.writeToBuffer();
      
      final deserializedApp = App.fromBuffer(appBuffer);
      final deserializedConsensus = Consensus.fromBuffer(consensusBuffer);
      
      expect(deserializedApp.protocol, Int64.MAX_VALUE);
      expect(deserializedConsensus.block, Int64.MAX_VALUE);
      expect(deserializedConsensus.app, Int64.MAX_VALUE);
    });

    test('should maintain consistency across different operations', () {
      final versions = [
        {'app': App(protocol: Int64(1), software: 'test v1.0.0'), 'consensus': Consensus(block: Int64(11), app: Int64(1))},
        {'app': App(protocol: Int64(2), software: 'test v2.0.0'), 'consensus': Consensus(block: Int64(12), app: Int64(2))},
        {'app': App(protocol: Int64(0), software: 'legacy v0.1.0'), 'consensus': Consensus(block: Int64(10), app: Int64(0))},
      ];
      
      for (final versionSet in versions) {
        final app = versionSet['app'] as App;
        final consensus = versionSet['consensus'] as Consensus;
        
        // Test clone consistency
        final clonedApp = app.clone();
        final clonedConsensus = consensus.clone();
        
        expect(clonedApp.protocol, app.protocol);
        expect(clonedApp.software, app.software);
        expect(clonedConsensus.block, consensus.block);
        expect(clonedConsensus.app, consensus.app);
        
        // Test serialization consistency
        final appJson = app.writeToJson();
        final consensusJson = consensus.writeToJson();
        
        final appFromJson = App.fromJson(appJson);
        final consensusFromJson = Consensus.fromJson(consensusJson);
        
        expect(appFromJson.protocol, app.protocol);
        expect(consensusFromJson.block, consensus.block);
      }
    });
  });
} 