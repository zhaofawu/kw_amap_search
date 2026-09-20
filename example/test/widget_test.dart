import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kw_amap_search_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('kw_amap_search');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getPlatformVersion') {
            return 'Android test';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('renders SDK and search controls', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.textContaining('Running on: Android test'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Android Key'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Radius meters'), findsOneWidget);
  });

  for (final (firstToFinish, cancelFirst) in [
    ('reverseGeocode', false),
    ('searchAround', false),
    ('reverseGeocode', true),
    ('searchAround', true),
  ]) {
    testWidgets(
      '$firstToFinish stays independent (cancel first: $cancelFirst)',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pending = <String, Completer<Object?>>{};
        final ids = <String, String>{};
        final cancellations = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'getPlatformVersion') return 'test';
              if (call.method == 'searchAround' ||
                  call.method == 'reverseGeocode') {
                ids[call.method] = call.arguments['requestId'] as String;
                final response = Completer<Object?>();
                pending[ids[call.method]!] = response;
                return response.future;
              }
              if (call.method == 'cancelRequest') {
                final id = call.arguments['requestId'] as String;
                cancellations.add(id);
                pending[id]!.completeError(
                  PlatformException(code: 'cancelled'),
                );
                return true;
              }
              return null;
            });
        await tester.pumpWidget(const MyApp());
        await tester.pump();
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await tester.ensureVisible(find.text('Both'));
        await tester.tap(find.text('Both'));
        await tester.pump();
        expect(ids.keys, containsAll(['reverseGeocode', 'searchAround']));

        final reverse = <String, Object?>{
          'requestedLocation': {'latitude': 31.2304, 'longitude': 121.4737},
          'formattedAddress': 'Independent reverse result',
        };
        final nearby = <Object?>[
          {'poiId': 'sample', 'title': 'Independent nearby result'},
        ];
        final other = firstToFinish == 'reverseGeocode'
            ? 'searchAround'
            : 'reverseGeocode';
        Future<void> cancelOther() async {
          final cancelButton = find.byTooltip('Cancel ${ids[other]}');
          await tester.ensureVisible(cancelButton);
          await tester.tap(cancelButton);
          await tester.pump();
        }

        if (cancelFirst) {
          await cancelOther();
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }
        pending[ids[firstToFinish]]!.complete(
          firstToFinish == 'reverseGeocode' ? reverse : nearby,
        );
        await tester.pump();
        final displayed = firstToFinish == 'reverseGeocode'
            ? 'Independent reverse result'
            : 'Independent nearby result';
        expect(find.text(displayed), findsOneWidget);
        if (!cancelFirst) {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          await cancelOther();
        }
        expect(cancellations, [ids[other]]);
        expect(find.text(displayed), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('query controls serialize and invalid input stays visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final queries = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getPlatformVersion') return 'test';
          if (call.method == 'searchAround') {
            queries.add(call);
            return <Object?>[];
          }
          if (call.method == 'reverseGeocode') {
            queries.add(call);
            return {
              'requestedLocation': {'latitude': 31.2304, 'longitude': 121.4737},
            };
          }
          return null;
        });
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    for (final (label, value) in [
      ('Page', '2'),
      ('Page size', '5'),
      ('Radius meters', '300'),
      ('Timeout ms', '2500'),
    ]) {
      final input = find.widgetWithText(TextField, label);
      await tester.ensureVisible(input);
      await tester.enterText(input, value);
    }
    await tester.ensureVisible(find.text('Comprehensive'));
    await tester.tap(find.text('Comprehensive'));
    await tester.pump();
    await tester.ensureVisible(find.text('Nearby'));
    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();
    final arguments = queries.single.arguments as Map;
    expect(arguments['pageNum'], 2);
    expect(arguments['pageSize'], 5);
    expect(arguments['radius'], 300);
    expect(arguments['timeoutMs'], 2500);
    expect(arguments['sortRule'], 'comprehensive');
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    await tester.ensureVisible(find.text('Reverse'));
    await tester.tap(find.text('Reverse'));
    await tester.pumpAndSettle();
    expect(queries.last.arguments['includeExtensions'], isFalse);
    for (final (label, value, action) in [
      ('Page', '0', 'Nearby'),
      ('Radius meters', 'invalid', 'Reverse'),
      ('Timeout ms', '0', 'Keyword'),
    ]) {
      final input = find.widgetWithText(TextField, label);
      await tester.ensureVisible(input);
      await tester.enterText(input, value);
      final button = find.ancestor(
        of: find.text(action),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('invalid_argument'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
    expect(queries.length, 2);
  });

  testWidgets('failed query can retry; rapid submits and disposal clean up', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = <String, Completer<Object?>>{};
    final cancelled = <String>[];
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getPlatformVersion') return 'test';
          if (call.method == 'searchKeyword') {
            calls++;
            if (calls == 1) {
              throw PlatformException(code: 'sdk_error', message: 'offline');
            }
            final id = call.arguments['requestId'] as String;
            expect(pending.containsKey(id), isFalse);
            pending[id] = Completer<Object?>();
            return pending[id]!.future;
          }
          if (call.method == 'cancelRequest') {
            final id = call.arguments['requestId'] as String;
            cancelled.add(id);
            pending
                .remove(id)!
                .completeError(PlatformException(code: 'cancelled'));
            return true;
          }
          return null;
        });
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final button = find.widgetWithText(FilledButton, 'Keyword');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('sdk_error: offline'), findsWidgets);
    for (var i = 0; i < 3; i++) {
      await tester.tap(button);
    }
    await tester.pump();
    expect(pending, isNotEmpty);
    final activeIds = pending.keys.toSet();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(cancelled.toSet(), activeIds);
    expect(pending, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
