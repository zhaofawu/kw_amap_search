import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kw_amap_search/kw_amap_search_method_channel.dart';
import 'package:kw_amap_search/search_result_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelKwAmapSearch();
  const channel = MethodChannel('kw_amap_search');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          calls.add(methodCall);

          if (methodCall.method == 'getPlatformVersion') {
            return '42';
          }
          if (methodCall.method == 'searchKeyword' ||
              methodCall.method == 'searchAround') {
            return <Object?>[
              {
                ..._samplePoiJson(),
                if (methodCall.method == 'searchKeyword') 'distance': null,
              },
            ];
          }
          if (methodCall.method == 'reverseGeocode') {
            return _sampleRegeocodeJson();
          }
          if (methodCall.method == 'cancelRequest') {
            return true;
          }
          if (methodCall.method == 'failingSearch') {
            throw PlatformException(
              code: 'AMAP_SEARCH_ERROR',
              message: 'Invalid user key',
              details: <String, Object?>{'errorCode': 1002},
            );
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
    expect(calls.single.method, 'getPlatformVersion');
  });

  test('invokes setup and privacy methods with expected arguments', () async {
    await platform.setApiKey('android-key', 'ios-key');
    await platform.updatePrivacyShow(true, false);
    await platform.updatePrivacyAgree(true);

    expect(calls[0].method, 'setApiKey');
    expect(calls[0].arguments, <String, Object?>{
      'androidKey': 'android-key',
      'iosKey': 'ios-key',
    });
    expect(calls[1].method, 'updatePrivacyShow');
    expect(calls[1].arguments, <String, Object?>{
      'hasContains': true,
      'hasShow': false,
    });
    expect(calls[2].method, 'updatePrivacyAgree');
    expect(calls[2].arguments, <String, Object?>{'hasAgree': true});
  });

  test('searchByKeyword invokes native method and parses POI items', () async {
    final results = await platform.searchByKeyword(
      const AmapKeywordSearchQuery(
        keyword: 'coffee',
        city: 'Shanghai',
        types: '050000',
        pageSize: 10,
        pageNum: 2,
      ),
    );

    expect(calls.single.method, 'searchKeyword');
    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(arguments['keyword'], 'coffee');
    expect(arguments['city'], 'Shanghai');
    expect(arguments['types'], '050000');
    expect(arguments['pageSize'], 10);
    expect(arguments['pageNum'], 2);
    expect(arguments['coordinateType'], 'gcj02');
    expect(arguments['requestId'], isA<String>());
    expect(arguments['timeoutMs'], 10000);
    expect(results.single.name, 'Sample POI');
    expect(results.single.location!.longitude, 121.4737);
    expect(results.single.distanceMeters, isNull);
    expect(results.single.sdkDistanceMeters, isNull);
  });

  test(
    'searchNearby invokes native method with radius and parses POI items',
    () async {
      final results = await platform.searchNearby(
        const AmapAroundSearchQuery(
          center: AmapLatLng(latitude: 31.2304, longitude: 121.4737),
          radius: 1500,
          keyword: 'tea',
          city: 'Shanghai',
          types: '050000',
          pageSize: 12,
          pageNum: 3,
          sortRule: AmapAroundSortRule.comprehensive,
        ),
      );

      expect(calls.single.method, 'searchAround');
      final arguments = calls.single.arguments as Map<Object?, Object?>;
      expect(arguments['latitude'], 31.2304);
      expect(arguments['longitude'], 121.4737);
      expect(arguments['radius'], 1500);
      expect(arguments['keyword'], 'tea');
      expect(arguments['city'], 'Shanghai');
      expect(arguments['types'], '050000');
      expect(arguments['pageSize'], 12);
      expect(arguments['pageNum'], 3);
      expect(arguments['sortRule'], 'comprehensive');
      expect(arguments['coordinateType'], 'gcj02');
      expect(results.single.id, 'B001');
      expect(results.single.photos.single.title, 'front');
      expect(results.single.distanceMeters, closeTo(0, 1));
    },
  );

  test(
    'reverseGeocode invokes native method and parses structured result',
    () async {
      final result = await platform.reverseGeocode(
        const AmapReverseGeocodeQuery(
          point: AmapLatLng(latitude: 31.2304, longitude: 121.4737),
          radius: 300,
        ),
        options: const AmapSearchRequestOptions(requestId: 'reverse-1'),
      );

      expect(calls.single.method, 'reverseGeocode');
      final arguments = calls.single.arguments as Map<Object?, Object?>;
      expect(arguments['requestId'], 'reverse-1');
      expect(arguments['timeoutMs'], 10000);
      expect(arguments['coordinateType'], 'gcj02');
      expect(arguments['includeExtensions'], isTrue);
      expect(result.formattedAddress, 'Sample formatted address');
      expect(result.pois.single.id, 'B001');
      expect(result.aois.single.containsPoint, isNull);
    },
  );

  test('cancelRequest invokes native method', () async {
    expect(await platform.cancelRequest('request-1'), isTrue);
    expect(calls.single.method, 'cancelRequest');
    expect(calls.single.arguments, <String, Object?>{'requestId': 'request-1'});
  });

  for (final cancelFails in [false, true]) {
    test(
      'timeout is bounded when cancellation ${cancelFails ? 'fails' : 'hangs'}',
      () async {
        final pendingSearch = Completer<Object?>();
        final pendingCancel = Completer<Object?>();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              if (call.method == 'cancelRequest') {
                if (cancelFails) throw PlatformException(code: 'channel-error');
                return pendingCancel.future;
              }
              return pendingSearch.future;
            });
        try {
          await expectLater(
            platform
                .searchByKeyword(
                  const AmapKeywordSearchQuery(keyword: 'coffee'),
                  options: const AmapSearchRequestOptions(
                    requestId: 'timeout-test',
                    timeout: Duration(milliseconds: 10),
                  ),
                )
                .timeout(const Duration(seconds: 1)),
            throwsA(
              isA<AmapSearchException>().having(
                (error) => error.code,
                'code',
                'timeout',
              ),
            ),
          );
          expect(calls.last.method, 'cancelRequest');
          expect(calls.last.arguments['requestId'], 'timeout-test');
        } finally {
          pendingCancel.complete(false);
          pendingSearch.complete(<Object?>[]);
        }
      },
    );
  }

  test('converts PlatformException into AmapSearchException', () async {
    final testPlatform = _FailingMethodChannelKwAmapSearch();

    await expectLater(
      testPlatform.triggerFailingSearch(),
      throwsA(
        isA<AmapSearchException>()
            .having((error) => error.code, 'code', 'AMAP_SEARCH_ERROR')
            .having((error) => error.details, 'details', <String, Object?>{
              'errorCode': 1002,
            }),
      ),
    );
  });
}

Map<String, Object?> _sampleRegeocodeJson() {
  return <String, Object?>{
    'requestedLocation': <String, Object?>{
      'latitude': 31.2304,
      'longitude': 121.4737,
    },
    'coordinateType': 'gcj02',
    'formattedAddress': 'Sample formatted address',
    'addressComponent': <String, Object?>{
      'province': '上海市',
      'district': '黄浦区',
      'streetNumber': <String, Object?>{
        'street': '南京东路',
        'number': '1号',
        'sdkDistanceMeters': 12,
      },
    },
    'pois': <Object?>[_samplePoiJson()],
    'aois': <Object?>[
      <String, Object?>{'id': 'AOI1', 'name': 'Sample AOI'},
    ],
    'roads': <Object?>[],
    'roadIntersections': <Object?>[],
  };
}

class _FailingMethodChannelKwAmapSearch extends MethodChannelKwAmapSearch {
  Future<void> triggerFailingSearch() async {
    await invokeNative<void>('failingSearch');
  }
}

Map<String, Object?> _samplePoiJson() {
  return <String, Object?>{
    'adCode': '310101',
    'adName': 'Huangpu',
    'cityName': 'Shanghai',
    'cityCode': '021',
    'indoorData': <String, Object?>{
      'floor': 1,
      'floorName': 'F1',
      'poiId': 'indoor-1',
    },
    'businessArea': 'People Square',
    'direction': 'east',
    'distance': 120,
    'email': 'poi@example.com',
    'enter': <String, Object?>{'latitude': 31.2, 'longitude': 121.4},
    'exit': <String, Object?>{'latitude': 31.3, 'longitude': 121.5},
    'isIndoorMap': true,
    'latLonPoint': <String, Object?>{
      'latitude': 31.2304,
      'longitude': 121.4737,
    },
    'parkingType': 'ground',
    'photos': <Object?>[
      <String, Object?>{
        'title': 'front',
        'url': 'https://example.com/photo.jpg',
      },
    ],
    'poiExtension': <String, Object?>{'openTime': '09:00-18:00'},
    'poiId': 'B001',
    'postcode': '200000',
    'provinceCode': '310000',
    'provinceName': 'Shanghai',
    'shopID': 'shop-1',
    'snippet': 'Sample address',
    'subPois': <Object?>[
      <String, Object?>{
        'title': 'Sub POI',
        'snippet': 'Sub address',
        'subTypeDes': 'entrance',
        'distance': 15,
        'poiId': 'S001',
        'subName': 'North Gate',
        'subLatLonPoint': <String, Object?>{
          'latitude': 31.2305,
          'longitude': 121.4738,
        },
      },
    ],
    'tel': '021-00000000',
    'title': 'Sample POI',
    'typeCode': '050000',
    'typeDes': 'Dining',
    'website': 'https://example.com',
  };
}
