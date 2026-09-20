import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kw_amap_search_example/main.dart';

import 'network_setup.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const androidKey = String.fromEnvironment('AMAP_ANDROID_KEY');
  const iosKey = String.fromEnvironment('AMAP_IOS_KEY');
  final key = Platform.isAndroid ? androidKey : iosKey;

  testWidgets(
    'example real SDK controls, paging, retry and page disposal',
    (tester) async {
      expect(const bool.fromEnvironment('AMAP_PRIVACY_AGREED'), isTrue);
      await waitForNetworkPermission();
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      Future<void> reveal(Finder finder) async {
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pump();
        await tester.scrollUntilVisible(
          finder,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
      }

      Future<void> fill(String label, String value) async {
        final field = find.widgetWithText(TextField, label);
        await reveal(field);
        await tester.enterText(field, value);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.text == value,
          isTrue,
          reason: '$label input was not applied',
        );
      }

      Finder button(String name) => find.ancestor(
        of: find.text(name),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      );
      var requestNumber = 0;
      Future<void> submit(String name, {String status = 'success'}) async {
        await reveal(button(name));
        await tester.tap(button(name));
        await tester.pump();
        final elapsed = Stopwatch()..start();
        while (tester.widget<ButtonStyleButton>(button(name)).onPressed ==
                null &&
            elapsed.elapsed < const Duration(seconds: 20)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          tester.widget<ButtonStyleButton>(button(name)).onPressed,
          isNotNull,
        );
        for (final operation
            in name == 'Both' ? ['reverse', 'nearby'] : [name.toLowerCase()]) {
          final title = find.text('example-${++requestNumber}-$operation');
          await reveal(title);
          final tile = tester.widget<ListTile>(
            find.ancestor(of: title, matching: find.byType(ListTile)),
          );
          expect((tile.subtitle! as Text).data, startsWith(status));
        }
      }

      var surfaceConverted = false;
      Future<void> screenshot(String name) async {
        if (Platform.isAndroid && !surfaceConverted) {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
        }
        await tester.pump();
        await binding.takeScreenshot('${Platform.operatingSystem}-$name');
      }

      await fill(Platform.isAndroid ? 'Android Key' : 'iOS Key', key);
      await reveal(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await fill('Latitude', '22.85687178770656');
      await fill('Longitude', '108.28107380400866');
      await fill('City', '南宁');
      await fill('Keyword', '兔喜');
      await fill('Radius meters', '300');
      await fill('Page size', '5');
      if (const bool.fromEnvironment('AMAP_TEST_UI_NETWORK_RECOVERY')) {
        await fill(
          'Keyword',
          'offline-${DateTime.now().microsecondsSinceEpoch}',
        );
        await screenshot('network-ready');
        await waitForDeviceNetwork(online: false);
        await submit('Keyword', status: 'sdk_error:');
        await screenshot('offline');
        debugPrint(
          'AMAP_SETUP: UI offline error verified; restore network now.',
        );
        await waitForDeviceNetwork(online: true);
        await submit('Keyword');
        await screenshot('network-recovery');
        debugPrint('AMAP_ACCEPTANCE same-process UI network recovery: passed');
        return;
      }
      await submit('Both');
      await screenshot('both-results');
      await submit('Keyword');
      await fill('Keyword', '');
      await fill('Types', '060000');
      await fill('Page', '2');
      await submit('Nearby');
      expect(find.textContaining('"pageNum":2'), findsOneWidget);
      await screenshot('paging');

      await fill('Radius meters', 'invalid');
      await submit('Reverse', status: 'invalid_argument');
      await fill('Radius meters', '300');
      await fill('Timeout ms', '1');
      await submit('Reverse', status: 'timeout:');
      await fill('Timeout ms', '10000');
      await submit('Reverse');
      await screenshot('reverse');

      // Avoid cancelling a request already satisfied by the SDK's local cache.
      await fill(
        'Radius meters',
        '${301 + DateTime.now().microsecondsSinceEpoch % 500}',
      );
      await reveal(button('Both'));
      await tester.tap(button('Both'));
      await tester.pump();
      final cancelId = 'example-${++requestNumber}-reverse';
      final otherId = 'example-${++requestNumber}-nearby';
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      final cancel = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == 'Cancel $cancelId',
      );
      expect(tester.widget<IconButton>(cancel).onPressed, isNotNull);
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      for (final (id, status) in [
        (cancelId, 'cancelled'),
        (otherId, 'success'),
      ]) {
        final title = find.text(id);
        await reveal(title);
        final tile = tester.widget<ListTile>(
          find.ancestor(of: title, matching: find.byType(ListTile)),
        );
        expect((tile.subtitle! as Text).data, startsWith(status));
      }
      await screenshot('single-cancel');
      await reveal(button('Both'));
      for (var i = 0; i < 3; i++) {
        await tester.tap(button('Both'));
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(seconds: 2));
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('kw_amap_search example'), findsOneWidget);
      expect(tester.takeException(), isNull);
      debugPrint(
        'AMAP_ACCEPTANCE example UI: controls/paging/timeout/retry/cancel/rapid/disposal passed',
      );
    },
    skip: key.isEmpty,
  );
}
