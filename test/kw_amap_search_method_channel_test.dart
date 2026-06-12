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
            return <Object?>[_samplePoiJson()];
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
    expect(calls.single.arguments, <String, Object?>{
      'keyword': 'coffee',
      'city': 'Shanghai',
      'types': '050000',
      'pageSize': 10,
      'pageNum': 2,
    });
    expect(results.single.name, 'Sample POI');
    expect(results.single.location.longitude, 121.4737);
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
        ),
      );

      expect(calls.single.method, 'searchAround');
      expect(calls.single.arguments, <String, Object?>{
        'latitude': 31.2304,
        'longitude': 121.4737,
        'radius': 1500,
        'keyword': 'tea',
        'city': 'Shanghai',
        'types': '050000',
        'pageSize': 12,
        'pageNum': 3,
      });
      expect(results.single.id, 'B001');
      expect(results.single.photos.single.title, 'front');
    },
  );

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
