import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kw_amap_search/kw_amap_search.dart';

import 'network_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('privacy refusal and invalid mobile Key return errors', (
    tester,
  ) async {
    expect(const bool.fromEnvironment('AMAP_PRIVACY_AGREED'), isTrue);
    await waitForNetworkPermission();
    const query = AmapReverseGeocodeQuery(
      point: AmapLatLng(
        latitude: 22.85687178770656,
        longitude: 108.28107380400866,
      ),
    );
    const invalidKey = '00000000000000000000000000000000';
    await KwAmapSearch.setApiKey(invalidKey, invalidKey);
    await KwAmapSearch.updatePrivacyShow(true, true);
    await KwAmapSearch.updatePrivacyAgree(false);
    await expectLater(
      KwAmapSearch.reverseGeocode(query),
      throwsA(
        isA<AmapSearchException>().having(
          (error) {
            final details = error.details as Map?;
            debugPrint(
              'AMAP_ACCEPTANCE privacy-refused: '
              '${error.code}, nativeCode=${details?["nativeCode"]}',
            );
            return error.code;
          },
          'privacy error code',
          Platform.isAndroid ? 'sdk_error' : 'privacy_not_agreed',
        ),
      ),
    );
    await KwAmapSearch.updatePrivacyAgree(true);
    await expectLater(
      KwAmapSearch.reverseGeocode(query),
      throwsA(
        isA<AmapSearchException>().having(
          (error) {
            final details = error.details as Map?;
            debugPrint(
              'AMAP_ACCEPTANCE invalid-key: '
              '${error.code}, nativeCode=${details?["nativeCode"]}',
            );
            return error.code == 'sdk_error' && details?['nativeCode'] == 1002;
          },
          'invalid Key SDK error with native code 1002',
          isTrue,
        ),
      ),
    );
  });
}
