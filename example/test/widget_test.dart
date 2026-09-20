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
}
