import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kw_amap_search/kw_amap_search.dart';

import 'network_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const androidKey = String.fromEnvironment('AMAP_ANDROID_KEY');
  const iosKey = String.fromEnvironment('AMAP_IOS_KEY');
  final hasKey = (Platform.isAndroid ? androidKey : iosKey).isNotEmpty;

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final String? version = await KwAmapSearch.getPlatformVersion();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(version?.isNotEmpty, true);
  });

  group('real SDK acceptance', skip: !hasKey, () {
    setUpAll(() async {
      expect(
        const bool.fromEnvironment('AMAP_PRIVACY_AGREED'),
        isTrue,
        reason: 'Explicit SDK privacy consent is required for device tests.',
      );
      await waitForNetworkPermission();
      await KwAmapSearch.setApiKey(androidKey, iosKey);
      await KwAmapSearch.updatePrivacyShow(true, true);
      await KwAmapSearch.updatePrivacyAgree(true);
    });

    testWidgets(
      'offline request fails without empty success',
      (tester) async {
        if (const bool.fromEnvironment('AMAP_TEST_MANUAL_OFFLINE')) {
          await waitForDeviceNetwork(online: true);
          await waitForDeviceNetwork(online: false);
        }
        final elapsed = Stopwatch()..start();
        final query = AmapKeywordSearchQuery(
          keyword: 'kw-amap-offline-${DateTime.now().millisecondsSinceEpoch}',
          city: '南宁',
        );
        await expectLater(
          KwAmapSearch.searchByKeyword(
            query,
            options: const AmapSearchRequestOptions(
              timeout: Duration(seconds: 8),
            ),
          ),
          throwsA(
            isA<AmapSearchException>().having(
              (error) {
                final details = error.details as Map?;
                debugPrint(
                  'AMAP_ACCEPTANCE offline: ${error.code}, '
                  'nativeCode=${details?["nativeCode"]}',
                );
                return error.code == 'timeout' ||
                    (error.code == 'sdk_error' &&
                        const {
                          1102,
                          1103,
                          1802,
                          1804,
                          1805,
                          1806,
                        }.contains(details?['nativeCode']));
              },
              'network failure or bounded timeout',
              isTrue,
            ),
          ),
        );
        expect(elapsed.elapsed, lessThan(const Duration(seconds: 12)));
        if (const bool.fromEnvironment('AMAP_TEST_NETWORK_RECOVERY')) {
          debugPrint(
            'AMAP_SETUP: offline error verified; restore network now.',
          );
          await waitForDeviceNetwork(online: true);
          final retry = await KwAmapSearch.searchByKeyword(query);
          expect(retry, isEmpty);
          final reverse = await KwAmapSearch.reverseGeocode(
            const AmapReverseGeocodeQuery(point: _point),
          );
          expect(reverse.formattedAddress, isNotEmpty);
          debugPrint('AMAP_ACCEPTANCE same-process network recovery: passed');
        }
      },
      skip: !const bool.fromEnvironment('AMAP_TEST_OFFLINE'),
    );

    testWidgets('four sample queries and reverse extensions', (tester) async {
      const reverseQuery = AmapReverseGeocodeQuery(point: _point);
      final reverse = await KwAmapSearch.reverseGeocode(reverseQuery);
      expect(reverse.requestedLocation.toJson(), _point.toJson());
      expect(reverse.coordinateType, 'gcj02');
      expect(reverse.formattedAddress, isNotEmpty);
      expect(reverse.addressComponent?.adCode, isNotEmpty);
      _record('reverse', reverseQuery.toMethodArguments(), reverse.pois, {
        'formattedAddress': reverse.formattedAddress,
        'requestedLocation': reverse.requestedLocation.toJson(),
        'aoiCount': reverse.aois.length,
        'roadCount': reverse.roads.length,
        'intersectionCount': reverse.roadIntersections.length,
      });
      if (Platform.isAndroid) {
        for (final aoi in reverse.aois) {
          expect(aoi.containsPoint, isNull);
          expect(aoi.distanceToBoundaryMeters, isNull);
        }
      }

      for (final entry in {
        'default': const AmapAroundSearchQuery(
          center: _point,
          radius: 300,
          pageSize: 25,
        ),
        'explicit': const AmapAroundSearchQuery(
          center: _point,
          radius: 300,
          pageSize: 25,
          types: _types,
        ),
        'keyword': const AmapAroundSearchQuery(
          center: _point,
          radius: 300,
          pageSize: 25,
          keyword: '兔喜',
        ),
      }.entries) {
        final pois = await KwAmapSearch.searchNearby(entry.value);
        _record(entry.key, entry.value.toMethodArguments(), pois);
        expect(pois, isNotEmpty);
        for (final poi in pois) {
          expect(poi.id, isNotEmpty);
          if (poi.location != null) {
            expect(poi.distanceMeters, isNonNegative);
          }
          expect(poi.sdkDistanceMeters, anyOf(isNull, isNonNegative));
        }
        final distances = pois
            .map((poi) => poi.sdkDistanceMeters)
            .whereType<double>()
            .toList();
        expect(distances, orderedEquals([...distances]..sort()));
      }

      final base = await KwAmapSearch.reverseGeocode(
        const AmapReverseGeocodeQuery(point: _point, includeExtensions: false),
      );
      expect(base.formattedAddress, isNotEmpty);
      expect(base.pois, isEmpty);
      expect(base.aois, isEmpty);
      expect(base.roads, isEmpty);
      expect(base.roadIntersections, isEmpty);
    });

    testWidgets('category, paging and three concurrent query types', (
      tester,
    ) async {
      const firstQuery = AmapAroundSearchQuery(
        center: _point,
        radius: 300,
        types: '060000',
        pageSize: 5,
      );
      const secondQuery = AmapAroundSearchQuery(
        center: _point,
        radius: 300,
        types: '060000',
        pageSize: 5,
        pageNum: 2,
      );
      final first = await KwAmapSearch.searchNearby(firstQuery);
      final second = await KwAmapSearch.searchNearby(secondQuery);
      for (final poi in [...first, ...second]) {
        expect(poi.typeCode, startsWith('06'));
      }
      expect(first.length, 5);
      expect(second.length, 5);
      expect(
        first
            .map((poi) => poi.id)
            .toSet()
            .intersection(second.map((poi) => poi.id).toSet()),
        isEmpty,
      );
      _record('shopping-page-1', firstQuery.toMethodArguments(), first);
      _record('shopping-page-2', secondQuery.toMethodArguments(), second);

      const keywordQuery = AmapKeywordSearchQuery(keyword: '兔喜', city: '南宁');
      await Future.wait([
        KwAmapSearch.searchByKeyword(keywordQuery).then((pois) {
          expect(pois, isNotEmpty);
          for (final poi in pois) {
            expect(poi.distanceMeters, isNull);
            expect(poi.sdkDistanceMeters, isNull);
          }
          _record('concurrent-keyword', keywordQuery.toMethodArguments(), pois);
        }),
        KwAmapSearch.searchNearby(firstQuery).then((pois) {
          expect(pois.map((poi) => poi.id), first.map((poi) => poi.id));
        }),
        KwAmapSearch.reverseGeocode(
          const AmapReverseGeocodeQuery(point: _point),
        ).then((result) {
          expect(result.requestedLocation.toJson(), _point.toJson());
          expect(result.formattedAddress, isNotEmpty);
        }),
      ]);
    });

    testWidgets('duplicate, cancel, timeout and request ID reuse', (
      tester,
    ) async {
      const options = AmapSearchRequestOptions(requestId: 'device-cancel');
      const query = AmapReverseGeocodeQuery(point: _point, radius: 301);
      final cancelled = expectLater(
        KwAmapSearch.reverseGeocode(query, options: options),
        throwsA(_code('cancelled')),
      );
      final duplicate = expectLater(
        KwAmapSearch.reverseGeocode(query, options: options),
        throwsA(_code('duplicate_request_id')),
      );
      final independent = KwAmapSearch.searchNearby(
        const AmapAroundSearchQuery(center: _point, radius: 300, types: _types),
      );
      expect(await KwAmapSearch.cancelRequest('device-cancel'), isTrue);
      await Future.wait([cancelled, duplicate]);
      expect(await KwAmapSearch.cancelRequest('device-cancel'), isFalse);
      expect(await independent, isNotEmpty);
      final reused = await KwAmapSearch.searchByKeyword(
        const AmapKeywordSearchQuery(keyword: '兔喜', city: '南宁'),
        options: options,
      );
      expect(reused, isNotEmpty);
      expect(reused.first.distanceMeters, isNull);

      await expectLater(
        KwAmapSearch.reverseGeocode(
          const AmapReverseGeocodeQuery(point: _point, radius: 302),
          options: const AmapSearchRequestOptions(
            requestId: 'device-timeout',
            timeout: Duration(milliseconds: 1),
          ),
        ),
        throwsA(_code('timeout')),
      );
      expect(await KwAmapSearch.cancelRequest('device-timeout'), isFalse);
      final afterTimeout = await KwAmapSearch.reverseGeocode(
        query,
        options: const AmapSearchRequestOptions(requestId: 'device-timeout'),
      );
      expect(afterTimeout.formattedAddress, isNotEmpty);
      debugPrint(
        'AMAP_ACCEPTANCE lifecycle: duplicate/cancel/timeout/reuse passed',
      );
    });

    testWidgets('zero latitude or longitude and empty results are valid', (
      tester,
    ) async {
      for (final point in [
        const AmapLatLng(latitude: 0, longitude: 108),
        const AmapLatLng(latitude: 22, longitude: 0),
      ]) {
        final reverse = await KwAmapSearch.reverseGeocode(
          AmapReverseGeocodeQuery(point: point),
        );
        expect(reverse.requestedLocation.toJson(), point.toJson());
        expect(reverse.pois, isEmpty);
      }
      final pois = await KwAmapSearch.searchNearby(
        const AmapAroundSearchQuery(
          center: _point,
          radius: 300,
          keyword: 'kw_amap_no_poi_8395127',
        ),
      );
      expect(pois, isEmpty);
      debugPrint(
        'AMAP_ACCEPTANCE zero latitude/longitude: valid empty results',
      );
    });
  });
}

const _point = AmapLatLng(
  latitude: 22.85687178770656,
  longitude: 108.28107380400866,
);
const _types =
    '050000|060000|070000|080000|090000|100000|110000|120000|130000|140000|150000|160000|170000|190000';

Matcher _code(String code) =>
    isA<AmapSearchException>().having((error) => error.code, 'code', code);

void _record(
  String scenario,
  Map<String, Object?> query,
  List<SearchResultItem> pois, [
  Map<String, Object?> extra = const {},
]) {
  debugPrintSynchronously(
    'AMAP_ACCEPTANCE ${jsonEncode({
      'time': DateTime.now().toUtc().toIso8601String(),
      'platform': Platform.operatingSystem,
      'scenario': scenario,
      'query': {...query}..remove('requestId'),
      ...extra,
      'pois': pois.map((poi) => {'id': poi.id, 'name': poi.name, 'typeCode': poi.typeCode, 'location': poi.location?.toJson(), 'distanceMeters': poi.distanceMeters, 'sdkDistanceMeters': poi.sdkDistanceMeters}).toList(),
    })}',
  );
}
