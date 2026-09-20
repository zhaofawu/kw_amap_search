import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'iOS native privacy forwarding and immediate initialization failure',
    (tester) async {
      expect(const bool.fromEnvironment('AMAP_PRIVACY_AGREED'), isTrue);
      final result = await const MethodChannel(
        'kw_amap_search_example/native_tests',
      ).invokeMapMethod<String, dynamic>('privacyInitialization', true);
      expect(result?['initialized'], isTrue);
      expect(result?['failureCode'], 'not_initialized');
      debugPrint('AMAP_ACCEPTANCE native privacy/init regression: passed');
    },
    skip: !Platform.isIOS,
  );
}
