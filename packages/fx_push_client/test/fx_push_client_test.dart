import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:fx_push_client/fx_push_client.dart';

const _appId = '11111111-2222-4333-8444-555555555555';
const _installationId = 'FxWallet_installation-01';
final _serviceUrl = Uri.parse('https://notify.example.com');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final operation in <String>['start', 'synchronize']) {
    for (final active in <bool>[true, false]) {
      test('retries initialization via $operation after storage recovers, active=$active', () async {
        final storage = RecoverableReadStorage();
        final registrationKey = 'ab' * 32;
        storage.values.addAll(<String, String>{
          'fx_push_client.v1.$_appId.installation_id': _installationId,
          'fx_push_client.v1.$_appId.registration_key': registrationKey,
          'fx_push_client.v1.$_appId.desired_active': active.toString(),
          'fx_push_client.v1.$_appId.subscription_id': RecordingTransport.subscriptionId,
          'fx_push_client.v1.$_appId.revision': active ? '1' : '2',
        });
        final saved = Map<String, String>.of(storage.values);
        final transport = RecordingTransport();
        final endpoints = FxPushEndpointSource(_apns('aabb'));
        final client = FxPushClient(
          serviceUrl: _serviceUrl,
          appId: _appId,
          installationId: _installationId,
          secureStorage: storage,
          endpointSource: endpoints,
          transport: transport,
          retryDelays: _noDelay,
        );
        addTearDown(() async {
          await client.dispose();
          await endpoints.dispose();
        });

        await expectLater(client.start(), throwsA(same(storage.readError)));
        expect(storage.reads, 1);
        expect(storage.writes, 0);
        expect(storage.values, saved);
        expect(transport.requests, isEmpty);
        expect(client.state.value.phase, FxPushSyncPhase.failed);
        expect(client.state.value.lastError, same(storage.readError));
        expect(client.getBindingData(), isNull);

        storage.failReads = false;
        if (operation == 'start') {
          await client.start();
        } else {
          await client.synchronize();
        }

        expect(client.state.value.phase, FxPushSyncPhase.synchronized);
        expect(client.state.value.lastError, isNull);
        expect(client.state.value.installationId, _installationId);
        expect(client.state.value.subscriptionId, RecordingTransport.subscriptionId);
        expect(client.state.value.desiredActive, active);
        expect(storage.values, saved);
        expect(storage.writes, 2, reason: 'only the subscription response fields are written');
        expect(transport.requests, hasLength(1));
        if (active) {
          expect(client.getBindingData()!.registrationKey, registrationKey);
          expect(client.getBindingData()!.installationId, _installationId);
        } else {
          expect(client.getBindingData(), isNull);
        }

        final readsAfterRecovery = storage.reads;
        await client.start();
        await client.synchronize();
        expect(storage.reads, readsAfterRecovery, reason: 'successful initialization remains cached');
        expect(storage.values, saved);
        for (final request in transport.requests) {
          expect(request.body['installation_id'], _installationId);
          expect(request.registrationKey, registrationKey);
          expect(request.body['active'], active);
        }
      });
    }
  }

  test('shares pending initialization between concurrent start and synchronize calls', () async {
    final storage = BlockingReadStorage();
    final transport = RecordingTransport();
    final endpoints = FxPushEndpointSource(_apns('aabb'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpoints,
      transport: transport,
      retryDelays: _noDelay,
    );
    addTearDown(() async {
      if (!storage.releaseRead.isCompleted) storage.releaseRead.complete();
      await client.dispose();
      await endpoints.dispose();
    });

    final first = client.start();
    await storage.readStarted.future;
    final second = client.start();
    final sync = client.synchronize();
    await Future<void>.delayed(Duration.zero);
    expect(storage.reads, 0, reason: 'all calls wait on the same blocked first read');
    expect(storage.writes, 0);
    expect(transport.requests, isEmpty);

    storage.releaseRead.complete();
    await Future.wait(<Future<void>>[first, second, sync]);
    expect(client.state.value.phase, FxPushSyncPhase.synchronized);
    final binding = client.getBindingData()!;
    final readCount = storage.reads;
    await client.synchronize();
    expect(storage.reads, readCount);
    expect(client.getBindingData()!.toJson(), binding.toJson());
  });

  test(
    'creates stable installation identity and 32-byte lowercase credential',
    () async {
      final storage = MemorySecureStorage();
      final endpointSource = FxPushEndpointSource(_apns('aa11'));
      final firstTransport = RecordingTransport();
      final first = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: storage,
        endpointSource: endpointSource,
        transport: firstTransport,
        retryDelays: _noDelay,
      );

      await first.start();
      final firstRequest = firstTransport.requests.single;
      final firstBinding = first.getBindingData()!;
      expect(
        firstRequest.body['installation_id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(firstRequest.registrationKey, matches(RegExp(r'^[0-9a-f]{64}$')));
      await first.dispose();

      final secondTransport = RecordingTransport();
      final second = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: storage,
        endpointSource: endpointSource,
        transport: secondTransport,
        retryDelays: _noDelay,
      );
      expect(second.getBindingData(), isNull);
      await second.start();
      expect(second.getBindingData()!.toJson(), firstBinding.toJson());
      expect(secondTransport.requests, hasLength(1));

      expect(
        secondTransport.requests.single.body['installation_id'],
        firstRequest.body['installation_id'],
      );
      expect(
        secondTransport.requests.single.registrationKey,
        firstRequest.registrationKey,
      );
      await second.dispose();
      await endpointSource.dispose();
    },
  );

  for (final restartId in <String?>[_installationId, null]) {
    test('preserves a supplied identity on restart with installationId=$restartId', () async {
      final storage = MemorySecureStorage();
      final endpoints = FxPushEndpointSource(_apns('aabb'));
      final firstTransport = RecordingTransport();
      final first = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        installationId: _installationId,
        secureStorage: storage,
        endpointSource: endpoints,
        transport: firstTransport,
        retryDelays: _noDelay,
      );
      await first.start();
      final original = first.getBindingData()!;
      expect(firstTransport.requests.single.body['installation_id'], _installationId);
      expect(first.state.value.installationId, _installationId);
      expect(original.installationId, _installationId);
      expect(original.registrationKey, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(storage.values['fx_push_client.v1.$_appId.installation_id'], _installationId);
      expect(storage.values['fx_push_client.v1.$_appId.registration_key'], original.registrationKey);
      await first.dispose();

      final secondTransport = RecordingTransport();
      final second = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        installationId: restartId,
        secureStorage: storage,
        endpointSource: endpoints,
        transport: secondTransport,
        retryDelays: _noDelay,
      );
      expect(second.getBindingData(), isNull);
      await second.start();
      expect(second.getBindingData()!.toJson(), original.toJson());
      expect(secondTransport.requests.single.body['installation_id'], _installationId);
      expect(secondTransport.requests.single.registrationKey, original.registrationKey);
      await second.dispose();
      await endpoints.dispose();
    });
  }

  test('accepts a supplied ID matching an existing generated identity', () async {
    final storage = MemorySecureStorage();
    final endpoints = FxPushEndpointSource(_apns('aabb'));
    final first = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpoints,
      transport: RecordingTransport(),
      retryDelays: _noDelay,
    );
    await first.start();
    final original = first.getBindingData()!;
    await first.dispose();

    final transport = RecordingTransport();
    final second = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      installationId: original.installationId,
      secureStorage: storage,
      endpointSource: endpoints,
      transport: transport,
      retryDelays: _noDelay,
    );
    await second.start();
    expect(second.getBindingData()!.toJson(), original.toJson());
    expect(transport.requests.single.body['installation_id'], original.installationId);
    expect(transport.requests.single.registrationKey, original.registrationKey);
    await second.dispose();
    await endpoints.dispose();
  });

  test('rejects a conflicting identity without changing the stored subscription', () async {
    final storage = MemorySecureStorage();
    final endpoints = FxPushEndpointSource(_apns('aabb'));
    final first = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpoints,
      transport: RecordingTransport(),
      retryDelays: _noDelay,
    );
    await first.start();
    await first.setActive(false);
    await first.dispose();
    final saved = Map<String, String>.of(storage.values);
    final writeCount = storage.writes;
    final transport = RecordingTransport();
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      installationId: _installationId,
      secureStorage: storage,
      endpointSource: endpoints,
      transport: transport,
      retryDelays: _noDelay,
    );
    final conflict = isA<StateError>().having(
      (error) => error.message,
      'message',
      'installationId does not match the stored installation_id',
    );
    await expectLater(client.start(), throwsA(conflict));
    await expectLater(client.synchronize(), throwsA(conflict));
    await expectLater(client.setActive(true), throwsA(conflict));
    expect(client.state.value.phase, FxPushSyncPhase.failed);
    expect(client.state.value.lastError, conflict);
    expect(client.getBindingData(), isNull);
    expect(storage.values, saved);
    expect(storage.writes, writeCount);
    endpoints.update(_apns('ccdd'));
    await Future<void>.delayed(Duration.zero);
    expect(transport.requests, isEmpty);
    await client.dispose();

    final restored = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpoints,
      transport: transport,
      retryDelays: _noDelay,
    );
    await restored.start();
    expect(restored.state.value.desiredActive, isFalse);
    expect(transport.requests.single.body['installation_id'], saved['fx_push_client.v1.$_appId.installation_id']);
    expect(transport.requests.single.registrationKey, saved['fx_push_client.v1.$_appId.registration_key']);
    await restored.dispose();
    await endpoints.dispose();
  });

  test('detects identity conflicts before creating a missing registration key', () async {
    final storage = MemorySecureStorage();
    storage.values['fx_push_client.v1.$_appId.installation_id'] = _installationId.toLowerCase();
    final saved = Map<String, String>.of(storage.values);
    final endpoints = FxPushEndpointSource(_apns('aabb'));
    final transport = RecordingTransport();
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      installationId: _installationId,
      secureStorage: storage,
      endpointSource: endpoints,
      transport: transport,
      retryDelays: _noDelay,
    );
    await expectLater(client.start(), throwsStateError);
    expect(storage.values, saved);
    expect(storage.writes, 0);
    expect(transport.requests, isEmpty);
    expect(client.getBindingData(), isNull);
    await client.dispose();
    await endpoints.dispose();
  });

  test('rejects invalid supplied installation IDs before storage or transport', () async {
    final storage = MemorySecureStorage();
    final endpoints = FxPushEndpointSource(_apns('aabb'));
    final transport = RecordingTransport();
    for (final value in <String>['', 'with space', 'with.dot', 'with/slash', '安装编号', 'x' * 129]) {
      expect(
        () => FxPushClient(
          serviceUrl: _serviceUrl,
          appId: _appId,
          installationId: value,
          secureStorage: storage,
          endpointSource: endpoints,
          transport: transport,
        ),
        throwsA(isA<ArgumentError>().having((error) => error.name, 'name', 'installationId')),
      );
    }
    expect(storage.reads, 0);
    expect(storage.writes, 0);
    expect(transport.requests, isEmpty);
    await endpoints.dispose();
  });

  test('retries registration with the same supplied ID and credential', () async {
    final storage = MemorySecureStorage();
    final endpoints = FxPushEndpointSource(_apns('aabb'));
    final transport = FailOnceTransport();
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      installationId: _installationId,
      secureStorage: storage,
      endpointSource: endpoints,
      transport: transport,
      retryDelays: _noDelay,
    );
    await client.start();
    expect(transport.requests, hasLength(2));
    final binding = client.getBindingData()!;
    expect(binding.installationId, _installationId);
    for (final request in transport.requests) {
      expect(request.body['installation_id'], _installationId);
      expect(request.registrationKey, binding.registrationKey);
    }
    expect(storage.values['fx_push_client.v1.$_appId.installation_id'], _installationId);
    expect(storage.values['fx_push_client.v1.$_appId.registration_key'], binding.registrationKey);
    await client.dispose();
    await endpoints.dispose();
  });

  test(
    'sends full APNs state and exposes the server subscription state',
    () async {
      final transport = RecordingTransport();
      final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpointSource,
        transport: transport,
        retryDelays: _noDelay,
      );

      await client.start();

      expect(transport.requests.single.body, containsPair('app_id', _appId));
      expect(transport.requests.single.body, containsPair('active', true));
      expect(transport.requests.single.body, containsPair('provider', 'apns'));
      expect(transport.requests.single.body, containsPair('platform', 'ios'));
      expect(transport.requests.single.body, containsPair('token', 'aabbccdd'));
      expect(
        transport.requests.single.body,
        containsPair('apns_environment', 'sandbox'),
      );
      expect(
        client.state.value.subscriptionId,
        RecordingTransport.subscriptionId,
      );
      expect(client.state.value.revision, '1');
      expect(client.state.value.phase, FxPushSyncPhase.synchronized);
      await client.dispose();
      await endpointSource.dispose();
    },
  );

  test(
    'binding reads return one consistent secret snapshot without side effects',
    () async {
      final storage = MemorySecureStorage();
      final transport = RecordingTransport();
      final endpoints = FxPushEndpointSource(_apns('aabb'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: storage,
        endpointSource: endpoints,
        transport: transport,
        retryDelays: _noDelay,
      );
      final observed = <FxPushState>[];
      client.state.addListener(() => observed.add(client.state.value));

      expect(client.getBindingData(), isNull);
      expect(storage.reads, 0);
      expect(storage.writes, 0);
      expect(transport.requests, isEmpty);
      await client.start();

      final request = transport.requests.single;
      final data = client.getBindingData()!;
      expect(data.subscriptionId, client.state.value.subscriptionId);
      expect(data.installationId, request.body['installation_id']);
      expect(data.installationId, client.state.value.installationId);
      expect(data.registrationKey, request.registrationKey);
      expect(
        data.registrationKey,
        storage.values['fx_push_client.v1.$_appId.registration_key'],
      );
      expect(data.toJson(), <String, String>{
        'subscription_id': data.subscriptionId,
        'installation_id': data.installationId,
        'registration_key': data.registrationKey,
      });
      final readCount = storage.reads;
      final writeCount = storage.writes;
      final stateCount = observed.length;
      final originalState = client.state.value;
      data.toJson()['registration_key'] = 'changed-copy';
      expect(client.getBindingData()!.registrationKey, request.registrationKey);
      expect(client.getBindingData()!.toJson(), data.toJson());
      expect(storage.reads, readCount);
      expect(storage.writes, writeCount);
      expect(transport.requests, hasLength(1));
      expect(observed, hasLength(stateCount));
      expect(client.state.value, same(originalState));
      for (final text in <String>[
        data.toString(),
        '$data',
        client.toString(),
        client.state.toString(),
        for (final state in observed) '$state ${state.lastError}',
      ]) {
        expect(text, isNot(contains(data.registrationKey)));
      }
      expect(data.toString(), 'FxPushBindingData(redacted)');
      expect(data.toString(), isNot(contains(data.subscriptionId)));
      expect(data.toString(), isNot(contains(data.installationId)));

      await client.dispose();
      expect(client.getBindingData, throwsStateError);
      await endpoints.dispose();
    },
  );

  test(
    'waiting for an endpoint and first disable provide no binding data',
    () async {
      final transport = RecordingTransport(disabledSubscriptionId: null);
      final endpoints = FxPushEndpointSource();
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpoints,
        transport: transport,
        retryDelays: _noDelay,
      );
      await client.start();
      expect(client.state.value.phase, FxPushSyncPhase.waitingForEndpoint);
      expect(client.getBindingData(), isNull);
      expect(transport.requests, isEmpty);
      await client.setActive(false);
      expect(client.state.value.subscriptionId, isNull);
      expect(client.getBindingData(), isNull);
      expect(transport.requests, hasLength(1));
      await client.dispose();
      await endpoints.dispose();
    },
  );

  test(
    'pending enrollment and disposal never expose binding credentials',
    () async {
      final transport = BlockingTransport();
      final endpoints = FxPushEndpointSource(_apns('aabb'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpoints,
        transport: transport,
        retryDelays: _noDelay,
      );
      final start = client.start();
      await transport.firstStarted.future;
      expect(client.getBindingData(), isNull);
      await client.dispose();
      expect(client.getBindingData, throwsStateError);
      transport.releaseFirst.complete();
      await start;
      expect(client.getBindingData, throwsStateError);
      await endpoints.dispose();
    },
  );

  test('disabled subscription ID cannot be exposed during re-enable', () async {
    final transport = BlockingNextTransport();
    final endpoints = FxPushEndpointSource(_apns('aabb'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpoints,
      transport: transport,
      retryDelays: _noDelay,
    );
    await client.start();
    final original = client.getBindingData()!;
    await client.setActive(false);
    expect(client.state.value.subscriptionId, original.subscriptionId);
    expect(client.getBindingData(), isNull);
    final duringEnable = <FxPushBindingData?>[];
    client.state.addListener(() {
      if (client.state.value.desiredActive) {
        duringEnable.add(client.getBindingData());
      }
    });
    transport.blockNext = true;
    final enable = client.setActive(true);
    await transport.nextStarted.future;
    expect(duringEnable, isNotEmpty);
    expect(duringEnable, everyElement(isNull));
    expect(client.getBindingData(), isNull);
    transport.releaseNext.complete();
    await enable;
    expect(client.getBindingData()!.toJson(), original.toJson());
    // An already returned snapshot stays immutable; callers must discard it.
    expect(original.toJson(), client.getBindingData()!.toJson());
    await client.dispose();
    await endpoints.dispose();
  });

  test(
    'failed disable and failed re-enable with a saved ID fail closed',
    () async {
      final transport = SwitchableTransport();
      final endpoints = FxPushEndpointSource(_apns('aabb'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpoints,
        transport: transport,
        retryDelays: _noDelay,
      );
      await client.start();
      final data = client.getBindingData()!;
      transport.fail = true;
      await client.setActive(false);
      expect(client.state.value.subscriptionId, data.subscriptionId);
      expect(client.state.value.phase, FxPushSyncPhase.failed);
      expect(client.getBindingData(), isNull);
      await client.setActive(true);
      expect(client.getBindingData(), isNull);
      expect(
        client.state.value.lastError.toString(),
        isNot(contains(data.registrationKey)),
      );
      transport.fail = false;
      await client.synchronize();
      expect(client.getBindingData()!.toJson(), data.toJson());
      endpoints.update(null);
      await client.synchronize();
      expect(client.state.value.phase, FxPushSyncPhase.waitingForEndpoint);
      expect(client.getBindingData(), isNull);
      await client.dispose();
      await endpoints.dispose();
    },
  );

  test('rejects an invalid persisted desired active state', () async {
    final storage = MemorySecureStorage();
    storage.values['fx_push_client.v1.$_appId.desired_active'] = 'enabled';
    final transport = RecordingTransport();
    final endpointSource = FxPushEndpointSource(_apns('aabb'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    await expectLater(
      client.start(),
      throwsA(
        isA<FxPushStoredStateException>().having(
          (error) => error.field,
          'field',
          'desired_active',
        ),
      ),
    );
    expect(client.state.value.phase, FxPushSyncPhase.failed);
    expect(transport.requests, isEmpty);
    expect(client.getBindingData(), isNull);

    await client.dispose();
    await endpointSource.dispose();
  });

  test('sends FCM state without an APNs environment', () async {
    final transport = RecordingTransport();
    final endpointSource = FxPushEndpointSource(
      FxPushEndpoint(
        provider: FxPushProvider.fcm,
        platform: FxPushPlatform.android,
        token: 'fcm-token',
      ),
    );
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    await client.start();

    expect(transport.requests.single.body, containsPair('provider', 'fcm'));
    expect(transport.requests.single.body, containsPair('platform', 'android'));
    expect(transport.requests.single.body, containsPair('token', 'fcm-token'));
    expect(transport.requests.single.body, isNot(contains('apns_environment')));
    await client.dispose();
    await endpointSource.dispose();
  });

  test(
    'rejects provider and platform combinations that cannot be delivered',
    () {
      expect(
        () => FxPushEndpoint(
          provider: FxPushProvider.fcm,
          platform: FxPushPlatform.ios,
          token: 'fcm-token',
        ),
        throwsArgumentError,
      );
      expect(() => _apns('not-hex'), throwsArgumentError);
      expect(
        () => FxPushEndpoint(
          provider: FxPushProvider.apns,
          platform: FxPushPlatform.android,
          token: 'aabb',
          apnsEnvironment: FxApnsEnvironment.sandbox,
        ),
        throwsArgumentError,
      );
    },
  );

  for (final installationId in <String?>[null, _installationId]) {
    test('FCM token rotation preserves installationId=$installationId and credential', () async {
      final transport = RecordingTransport();
      final endpointSource = FxPushEndpointSource(
        FxPushEndpoint(
          provider: FxPushProvider.fcm,
          platform: FxPushPlatform.android,
          token: 'fcm-token-old',
        ),
      );
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        installationId: installationId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpointSource,
        transport: transport,
        retryDelays: _noDelay,
      );
      await client.start();
      final bindingBeforeRotation = client.getBindingData()!;
      if (installationId != null) {
        expect(bindingBeforeRotation.installationId, installationId);
      }

      endpointSource.update(
        FxPushEndpoint(
          provider: FxPushProvider.fcm,
          platform: FxPushPlatform.android,
          token: 'fcm-token-new',
        ),
      );
      for (var i = 0; i < 10 && transport.requests.length < 2; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(transport.requests, hasLength(2));
      await client.synchronize();
      expect(client.getBindingData()!.toJson(), bindingBeforeRotation.toJson());
      final requestCount = transport.requests.length;
      client.getBindingData();
      expect(transport.requests, hasLength(requestCount));
      expect(transport.requests.first.body['token'], 'fcm-token-old');
      expect(transport.requests.last.body['token'], 'fcm-token-new');
      expect(
        transport.requests.last.body['installation_id'],
        bindingBeforeRotation.installationId,
      );
      expect(
        transport.requests.last.registrationKey,
        bindingBeforeRotation.registrationKey,
      );
      await client.dispose();
      await endpointSource.dispose();
    });
  }

  test('persists disable first and sends the minimal disabled body', () async {
    final storage = MemorySecureStorage();
    final transport = RecordingTransport(disabledSubscriptionId: null);
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );
    await client.start();

    await client.setActive(false);

    final request = transport.requests.last;
    expect(request.body.keys, <String>{'app_id', 'installation_id', 'active'});
    expect(request.body['active'], false);
    expect(
      storage.values.values,
      contains('false'),
      reason: 'desired state must be durable before the request is sent',
    );
    expect(client.state.value.subscriptionId, isNull);
    expect(client.getBindingData(), isNull);
    await client.dispose();
    await endpointSource.dispose();
  });

  for (final toggles in const <(bool, bool)>[(true, false), (false, true)]) {
    test(
      'serializes ${toggles.$1} then ${toggles.$2} desired-state writes',
      () async {
        final storage = DelayedDesiredStateStorage();
        final transport = RecordingTransport();
        final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
        final client = FxPushClient(
          serviceUrl: _serviceUrl,
          appId: _appId,
          secureStorage: storage,
          endpointSource: endpointSource,
          transport: transport,
          retryDelays: _noDelay,
        );
        await client.start();
        storage.delayNextDesiredStateWrite();

        final first = client.setActive(toggles.$1);
        await storage.delayedWriteStarted.future;
        final second = client.setActive(toggles.$2);
        await Future<void>.delayed(Duration.zero);

        expect(
          storage.desiredStateWrites,
          <String>[toggles.$1.toString()],
          reason: 'the second write must wait for the first write',
        );
        storage.releaseDelayedWrite.complete();
        await Future.wait(<Future<void>>[first, second]);

        expect(storage.desiredStateWrites, <String>[
          toggles.$1.toString(),
          toggles.$2.toString(),
        ]);
        expect(storage.desiredActive, toggles.$2.toString());
        expect(client.state.value.desiredActive, toggles.$2);
        expect(transport.requests.last.body['active'], toggles.$2);
        await client.dispose();
        await endpointSource.dispose();
      },
    );
  }

  test(
    'serializes concurrent changes and sends the latest desired state',
    () async {
      final transport = BlockingTransport();
      final endpointSource = FxPushEndpointSource(_apns('0011'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpointSource,
        transport: transport,
        retryDelays: _noDelay,
      );

      final start = client.start();
      await transport.firstStarted.future;
      endpointSource.update(_apns('2233'));
      final disable = client.setActive(false);
      transport.releaseFirst.complete();
      await Future.wait(<Future<void>>[start, disable]);

      expect(transport.maxConcurrent, 1);
      expect(transport.requests.first.body['active'], true);
      expect(transport.requests.last.body, <String, Object>{
        'app_id': _appId,
        'installation_id': transport.requests.last.body['installation_id']!,
        'active': false,
      });
      await client.dispose();
      await endpointSource.dispose();
    },
  );

  test(
    'retry wakes for a state change and rebuilds a disabled request',
    () async {
      final transport = FailOnceTransport();
      final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpointSource,
        transport: transport,
        retryDelays: const <Duration>[
          Duration(minutes: 1),
          Duration.zero,
          Duration.zero,
        ],
      );

      final start = client.start();
      await transport.failed.future;
      await Future<void>.delayed(Duration.zero);
      expect(client.state.value.phase, FxPushSyncPhase.retryScheduled);
      expect(client.getBindingData(), isNull);
      await client.setActive(false);
      await start;

      expect(transport.requests, hasLength(2));
      expect(transport.requests.first.body['active'], true);
      expect(transport.requests.last.body['active'], false);
      await client.dispose();
      await endpointSource.dispose();
    },
  );

  test('resumed lifecycle queues another synchronization', () async {
    final transport = RecordingTransport();
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );
    await client.start();

    client.didChangeAppLifecycleState(AppLifecycleState.resumed);
    for (var i = 0; i < 10 && transport.requests.length < 2; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(transport.requests, hasLength(2));
    await client.dispose();
    await endpointSource.dispose();
  });

  test('does not retry a non-retryable enrollment error', () async {
    final transport = AlwaysFailTransport(
      const FxPushHttpException(statusCode: 401, code: 'UNAUTHORIZED'),
    );
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    await client.start();

    expect(transport.calls, 1);
    expect(client.state.value.phase, FxPushSyncPhase.failed);
    expect(client.getBindingData(), isNull);
    await client.dispose();
    await endpointSource.dispose();
  });

  test('stops after three retries for a retryable error', () async {
    final transport = AlwaysFailTransport(
      const FxPushHttpException(statusCode: 503),
    );
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    await client.start();

    expect(transport.calls, 4);
    expect(client.state.value.phase, FxPushSyncPhase.failed);
    await client.dispose();
    await endpointSource.dispose();
  });

  test('rejects an active response without a subscription ID', () async {
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: NullActiveSubscriptionTransport(),
      retryDelays: _noDelay,
    );

    await client.start();

    expect(client.state.value.phase, FxPushSyncPhase.failed);
    expect(client.state.value.lastError, isA<FxPushProtocolException>());
    expect(client.state.value.subscriptionId, isNull);
    expect(client.getBindingData(), isNull);
    await client.dispose();
    await endpointSource.dispose();
  });

  test(
    'does not attach observers when disposed during initialization',
    () async {
      final storage = BlockingReadStorage();
      final transport = RecordingTransport();
      final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: storage,
        endpointSource: endpointSource,
        transport: transport,
        retryDelays: _noDelay,
      );

      final start = client.start();
      await storage.readStarted.future;
      expect(client.getBindingData(), isNull);
      await client.dispose();
      storage.releaseRead.complete();

      await expectLater(start, throwsStateError);
      endpointSource.update(_apns('eeff'));
      await Future<void>.delayed(Duration.zero);
      expect(transport.requests, isEmpty);
      await endpointSource.dispose();
    },
  );
}

const _noDelay = <Duration>[Duration.zero, Duration.zero, Duration.zero];

FxPushEndpoint _apns(String token) => FxPushEndpoint(
      provider: FxPushProvider.apns,
      platform: FxPushPlatform.ios,
      token: token,
      apnsEnvironment: FxApnsEnvironment.sandbox,
    );

class MemorySecureStorage implements FxPushSecureStorage {
  final Map<String, String> values = <String, String>{};
  int reads = 0;
  int writes = 0;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async {
    reads++;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writes++;
    values[key] = value;
  }
}

class RecoverableReadStorage extends MemorySecureStorage {
  bool failReads = true;
  final readError = StateError('secure storage temporarily unavailable');

  @override
  Future<String?> read(String key) async {
    if (failReads) {
      reads++;
      throw readError;
    }
    return super.read(key);
  }
}

class BlockingReadStorage extends MemorySecureStorage {
  final Completer<void> readStarted = Completer<void>();
  final Completer<void> releaseRead = Completer<void>();
  var _blocked = false;

  @override
  Future<String?> read(String key) async {
    if (!_blocked) {
      _blocked = true;
      readStarted.complete();
      await releaseRead.future;
    }
    return super.read(key);
  }
}

class DelayedDesiredStateStorage extends MemorySecureStorage {
  final Completer<void> delayedWriteStarted = Completer<void>();
  final Completer<void> releaseDelayedWrite = Completer<void>();
  final List<String> desiredStateWrites = <String>[];
  var _delayNext = false;

  String? get desiredActive {
    for (final entry in values.entries) {
      if (entry.key.endsWith('.desired_active')) return entry.value;
    }
    return null;
  }

  void delayNextDesiredStateWrite() {
    desiredStateWrites.clear();
    _delayNext = true;
  }

  @override
  Future<void> write(String key, String value) async {
    if (key.endsWith('.desired_active')) {
      desiredStateWrites.add(value);
      if (_delayNext) {
        _delayNext = false;
        delayedWriteStarted.complete();
        await releaseDelayedWrite.future;
      }
    }
    await super.write(key, value);
  }
}

class RecordingTransport implements FxPushSubscriptionTransport {
  RecordingTransport({this.disabledSubscriptionId = subscriptionId});

  static const subscriptionId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
  final String? disabledSubscriptionId;
  final List<FxPushSubscriptionRequest> requests =
      <FxPushSubscriptionRequest>[];

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    requests.add(request);
    final active = request.body['active']! as bool;
    return FxPushSubscriptionResponse(
      subscriptionId: active ? subscriptionId : disabledSubscriptionId,
      revision: active
          ? '1'
          : disabledSubscriptionId == null
              ? '0'
              : '2',
      active: active,
    );
  }
}

class BlockingTransport extends RecordingTransport {
  final Completer<void> firstStarted = Completer<void>();
  final Completer<void> releaseFirst = Completer<void>();
  var concurrent = 0;
  var maxConcurrent = 0;

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    concurrent++;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    if (!firstStarted.isCompleted) {
      firstStarted.complete();
      await releaseFirst.future;
    }
    final response = await super.synchronize(request);
    concurrent--;
    return response;
  }
}

class FailOnceTransport extends RecordingTransport {
  final Completer<void> failed = Completer<void>();
  var _shouldFail = true;

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    requests.add(request);
    if (_shouldFail) {
      _shouldFail = false;
      failed.complete();
      throw const FxPushHttpException(statusCode: 503);
    }
    final active = request.body['active']! as bool;
    return FxPushSubscriptionResponse(
      subscriptionId: active ? RecordingTransport.subscriptionId : null,
      revision: active ? '1' : '0',
      active: active,
    );
  }
}

class AlwaysFailTransport implements FxPushSubscriptionTransport {
  AlwaysFailTransport(this.error);
  final Object error;
  int calls = 0;

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    calls++;
    throw error;
  }
}

class NullActiveSubscriptionTransport implements FxPushSubscriptionTransport {
  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async =>
      const FxPushSubscriptionResponse(
        subscriptionId: null,
        revision: '1',
        active: true,
      );
}

class BlockingNextTransport extends RecordingTransport {
  bool blockNext = false;
  final Completer<void> nextStarted = Completer<void>();
  final Completer<void> releaseNext = Completer<void>();

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    if (blockNext) {
      blockNext = false;
      nextStarted.complete();
      await releaseNext.future;
    }
    return super.synchronize(request);
  }
}

class SwitchableTransport extends RecordingTransport {
  bool fail = false;

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    if (fail) throw const FxPushHttpException(statusCode: 401);
    return super.synchronize(request);
  }
}
