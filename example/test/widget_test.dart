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
}
