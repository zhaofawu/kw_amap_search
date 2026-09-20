import 'package:flutter_test/flutter_test.dart';
import 'package:kw_amap_search/kw_amap_search.dart';
import 'package:kw_amap_search/kw_amap_search_method_channel.dart';
import 'package:kw_amap_search/kw_amap_search_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKwAmapSearchPlatform
    with MockPlatformInterfaceMixin
    implements KwAmapSearchPlatform {
  String? androidKey;
  String? iosKey;
  bool? hasContains;
  bool? hasShow;
  bool? hasAgree;
  AmapKeywordSearchQuery? lastKeywordQuery;
  AmapAroundSearchQuery? lastAroundQuery;
  AmapReverseGeocodeQuery? lastReverseQuery;
  AmapSearchRequestOptions? lastOptions;
  String? cancelledRequestId;

  final results = <SearchResultItem>[
    SearchResultItem.fromJson(_samplePoiJson()),
  ];

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> setApiKey(String androidKey, String iosKey) async {
    this.androidKey = androidKey;
    this.iosKey = iosKey;
  }

  @override
  Future<void> updatePrivacyShow(bool hasContains, bool hasShow) async {
    this.hasContains = hasContains;
    this.hasShow = hasShow;
  }

  @override
  Future<void> updatePrivacyAgree(bool hasAgree) async {
    this.hasAgree = hasAgree;
  }

  @override
  Future<List<SearchResultItem>> searchByKeyword(
    AmapKeywordSearchQuery query, {
    AmapSearchRequestOptions? options,
  }) async {
    lastKeywordQuery = query;
    lastOptions = options;
    return results;
  }

  @override
  Future<List<SearchResultItem>> searchNearby(
    AmapAroundSearchQuery query, {
    AmapSearchRequestOptions? options,
  }) async {
    lastAroundQuery = query;
    lastOptions = options;
    return results;
  }

  @override
  Future<AmapRegeocodeResult> reverseGeocode(
    AmapReverseGeocodeQuery query, {
    AmapSearchRequestOptions? options,
  }) async {
    lastReverseQuery = query;
    lastOptions = options;
    return AmapRegeocodeResult.fromJson(_sampleRegeocodeJson());
  }

  @override
  Future<bool> cancelRequest(String requestId) async {
    cancelledRequestId = requestId;
    return true;
  }

  @override
  Future<List<SearchResultItem>> searchKeyword({
    required String keyword,
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
    AmapSearchRequestOptions? options,
  }) {
    return searchByKeyword(
      AmapKeywordSearchQuery(
        keyword: keyword,
        city: city,
        types: types,
        pageSize: pageSize,
        pageNum: pageNum,
      ),
      options: options,
    );
  }

  @override
  Future<List<SearchResultItem>> searchAround({
    required double latitude,
    required double longitude,
    int radius = 1000,
    String keyword = '',
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
    AmapAroundSortRule sortRule = AmapAroundSortRule.distance,
    AmapSearchRequestOptions? options,
  }) {
    return searchNearby(
      AmapAroundSearchQuery(
        center: AmapLatLng(latitude: latitude, longitude: longitude),
        radius: radius,
        keyword: keyword,
        city: city,
        types: types,
        pageSize: pageSize,
        pageNum: pageNum,
        sortRule: sortRule,
      ),
      options: options,
    );
  }
}

void main() {
  final initialPlatform = KwAmapSearchPlatform.instance;

  tearDown(() {
    KwAmapSearchPlatform.instance = initialPlatform;
  });

  test('$MethodChannelKwAmapSearch is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKwAmapSearch>());
  });

  test(
    'static facade keeps legacy calls while forwarding query objects',
    () async {
      final fakePlatform = MockKwAmapSearchPlatform();
      KwAmapSearchPlatform.instance = fakePlatform;

      expect(await KwAmapSearch.getPlatformVersion(), '42');

      await KwAmapSearch.setApiKey('android-key', 'ios-key');
      await KwAmapSearch.updatePrivacyShow(true, false);
      await KwAmapSearch.updatePrivacyAgree(true);
      final keywordResults = await KwAmapSearch.searchKeyword(
        keyword: 'coffee',
        city: 'Shanghai',
        types: '050000',
        pageSize: 10,
        pageNum: 2,
      );
      final aroundResults = await KwAmapSearch.searchAround(
        latitude: 31.2304,
        longitude: 121.4737,
        radius: 1500,
        keyword: 'tea',
        city: 'Shanghai',
        types: '050000',
        pageSize: 12,
        pageNum: 3,
        sortRule: AmapAroundSortRule.comprehensive,
      );
      final reverseResult = await KwAmapSearch.reverseGeocode(
        const AmapReverseGeocodeQuery(
          point: AmapLatLng(latitude: 31.2304, longitude: 121.4737),
        ),
        options: const AmapSearchRequestOptions(requestId: 'reverse-1'),
      );
      final cancelled = await KwAmapSearch.cancelRequest('reverse-1');

      expect(fakePlatform.androidKey, 'android-key');
      expect(fakePlatform.iosKey, 'ios-key');
      expect(fakePlatform.hasContains, isTrue);
      expect(fakePlatform.hasShow, isFalse);
      expect(fakePlatform.hasAgree, isTrue);
      expect(fakePlatform.lastKeywordQuery, isNotNull);
      expect(fakePlatform.lastKeywordQuery!.keyword, 'coffee');
      expect(fakePlatform.lastKeywordQuery!.city, 'Shanghai');
      expect(fakePlatform.lastKeywordQuery!.types, '050000');
      expect(fakePlatform.lastKeywordQuery!.pageSize, 10);
      expect(fakePlatform.lastKeywordQuery!.pageNum, 2);
      expect(fakePlatform.lastAroundQuery, isNotNull);
      expect(fakePlatform.lastAroundQuery!.center.latitude, 31.2304);
      expect(fakePlatform.lastAroundQuery!.center.longitude, 121.4737);
      expect(fakePlatform.lastAroundQuery!.radius, 1500);
      expect(
        fakePlatform.lastAroundQuery!.sortRule,
        AmapAroundSortRule.comprehensive,
      );
      expect(fakePlatform.lastReverseQuery!.radius, 300);
      expect(fakePlatform.lastOptions!.requestId, 'reverse-1');
      expect(reverseResult.formattedAddress, 'Sample formatted address');
      expect(cancelled, isTrue);
      expect(fakePlatform.cancelledRequestId, 'reverse-1');
      expect(keywordResults.single.name, 'Sample POI');
      expect(aroundResults.single.id, 'B001');
    },
  );

  test('new query-object API forwards without losing defaults', () async {
    final fakePlatform = MockKwAmapSearchPlatform();
    KwAmapSearchPlatform.instance = fakePlatform;

    await KwAmapSearch.searchByKeyword(
      const AmapKeywordSearchQuery(keyword: 'park'),
    );
    await KwAmapSearch.searchNearby(
      const AmapAroundSearchQuery(
        center: AmapLatLng(latitude: 31.2304, longitude: 121.4737),
      ),
    );

    expect(fakePlatform.lastKeywordQuery!.city, '');
    expect(fakePlatform.lastKeywordQuery!.pageSize, 20);
    expect(fakePlatform.lastKeywordQuery!.pageNum, 1);
    expect(fakePlatform.lastAroundQuery!.radius, 1000);
    expect(fakePlatform.lastAroundQuery!.sortRule, AmapAroundSortRule.distance);
  });

  test('SearchResultItem exposes clean names and legacy aliases', () {
    final item = SearchResultItem.fromJson(_samplePoiJson());

    expect(item.id, 'B001');
    expect(item.name, 'Sample POI');
    expect(item.address, 'Sample address');
    expect(item.location!.latitude, 31.2304);
    expect(item.location!.longitude, 121.4737);
    expect(item.indoor.floorName, 'F1');
    expect(item.entryLocation!.latitude, 31.2);
    expect(item.exitLocation!.longitude, 121.5);
    expect(item.photos.single.url, 'https://example.com/photo.jpg');
    expect(item.openingHours.openTime, '09:00-18:00');
    expect(item.children.single.location!.longitude, 121.4738);
    expect(item.sdkDistanceMeters, 120);

    // Legacy aliases intentionally stay available for apps that already shipped
    // against the first Android-only port.
    expect(item.poiId, item.id);
    expect(item.title, item.name);
    expect(item.snippet, item.address);
    expect(item.latLonPoint, item.location);
    expect(item.indoorData, item.indoor);
    expect(item.poiExtension, item.openingHours);
    expect(item.subPois, item.children);
    expect(item.toJson()['poiId'], 'B001');
  });

  test(
    'invalid and missing coordinates stay nullable instead of becoming zero',
    () {
      final item = SearchResultItem.fromJson(<String, Object?>{
        'poiId': 'B003',
        'title': 'No coordinate',
        'latLonPoint': <String, Object?>{'latitude': 'bad', 'longitude': 200},
      });

      expect(item.location, isNull);
      expect(item.distanceMeters, isNull);
      expect(item.toJson()['latLonPoint'], isNull);
    },
  );

  test('nearby and reverse models compute straight-line distance in Dart', () {
    const center = AmapLatLng(
      latitude: 22.85687178770656,
      longitude: 108.28107380400866,
    );
    final item = SearchResultItem.fromJson(<String, Object?>{
      'poiId': 'B0IASORQIR',
      'title': '兔喜快递',
      'latLonPoint': <String, Object?>{
        'latitude': 22.856825,
        'longitude': 108.281064,
      },
    }, queryCenter: center);
    final reverse = AmapRegeocodeResult.fromJson(_sampleRegeocodeJson());

    expect(item.distanceMeters, isNotNull);
    expect(item.distanceMeters!, lessThan(10));
    expect(reverse.coordinateType, amapCoordinateTypeGcj02);
    expect(reverse.addressComponent!.streetNumber!.sdkDistanceMeters, 12);
    expect(reverse.aois.single.containsPoint, isNull);
  });

  test('POI JSON round trip preserves distances and legacy distance', () {
    const center = AmapLatLng(
      latitude: 22.85687178770656,
      longitude: 108.28107380400866,
    );
    for (final sample in [
      ('B0IASORQIR', 22.856825, 108.281064, 5.3),
      ('B0I32YKT2M', 22.856449, 108.281183, 48.3),
    ]) {
      final original = SearchResultItem.fromJson({
        'poiId': sample.$1,
        'typeCode': '060000',
        'latLonPoint': {'latitude': sample.$2, 'longitude': sample.$3},
        'sdkDistanceMeters': sample.$4,
      }, queryCenter: center);
      final restored = SearchResultItem.fromJson(original.toJson());
      expect(restored.id, sample.$1);
      expect(restored.typeCode, '060000');
      expect(restored.location, original.location);
      expect(restored.distanceMeters, original.distanceMeters);
      expect(restored.distanceMeters, closeTo(sample.$4, 1));
      expect(restored.sdkDistanceMeters, original.sdkDistanceMeters);
      expect(restored.distance, original.distance);
    }
    const legacy = SearchResultItem(distance: 88);
    expect(SearchResultItem.fromJson(legacy.toJson()).distance, 88);
  });

  test('missing and negative distances stay null while zero remains valid', () {
    for (final value in [null, -1, double.nan, double.infinity]) {
      expect(
        SearchResultItem.fromJson({'distance': value}).sdkDistanceMeters,
        isNull,
      );
      expect(PoiChild.fromJson({'distance': value}).sdkDistanceMeters, isNull);
    }
    final item = SearchResultItem.fromJson({
      'latLonPoint': {'latitude': 0.0, 'longitude': 0.0},
      'distance': 0,
    }, queryCenter: const AmapLatLng(latitude: 0, longitude: 0));
    final restored = SearchResultItem.fromJson(item.toJson());
    expect(restored.distanceMeters, 0);
    expect(restored.sdkDistanceMeters, 0);
  });

  test('query validation rejects invalid inputs', () {
    expect(
      () => const AmapKeywordSearchQuery(keyword: ' ').toMethodArguments(),
      throwsA(
        isA<AmapSearchException>().having(
          (e) => e.code,
          'code',
          'invalid_argument',
        ),
      ),
    );
    expect(
      () => const AmapAroundSearchQuery(
        center: AmapLatLng(latitude: 91, longitude: 0),
      ).toMethodArguments(),
      throwsA(
        isA<AmapSearchException>().having(
          (e) => e.code,
          'code',
          'invalid_argument',
        ),
      ),
    );
    expect(
      () => const AmapReverseGeocodeQuery(
        point: AmapLatLng(latitude: 0, longitude: 0),
        radius: 3001,
      ).toMethodArguments(),
      throwsA(
        isA<AmapSearchException>().having(
          (e) => e.code,
          'code',
          'invalid_argument',
        ),
      ),
    );
  });

  test('legacy model constructors remain source compatible', () {
    final child = SubPois(
      title: 'Legacy Sub POI',
      snippet: 'Legacy sub address',
      subTypeDes: 'entrance',
      distance: 8,
      poiId: 'S002',
      subName: 'South Gate',
      subLatLonPoint: SubLatLonPoint(latitude: 31.1, longitude: 121.2),
    );

    final item = SearchResultItem(
      adCode: '310101',
      adName: 'Huangpu',
      cityName: 'Shanghai',
      cityCode: '021',
      indoorData: IndoorData(floor: 2, floorName: 'F2', poiId: 'indoor-2'),
      businessArea: 'People Square',
      direction: 'south',
      distance: 88,
      email: 'legacy@example.com',
      enter: Enter(latitude: 31.0, longitude: 121.0),
      exit: Exit(latitude: 31.3, longitude: 121.4),
      isIndoorMap: true,
      latLonPoint: LatLonPoint(latitude: 31.2304, longitude: 121.4737),
      parkingType: 'underground',
      photos: [Photos(title: 'legacy', url: 'https://example.com/old.jpg')],
      poiExtension: PoiExtension(openTime: '10:00-22:00'),
      poiId: 'B002',
      postcode: '200000',
      provinceCode: '310000',
      provinceName: 'Shanghai',
      shopID: 'shop-2',
      snippet: 'Legacy address',
      subPois: [child],
      tel: '021-11111111',
      title: 'Legacy POI',
      typeCode: '050000',
      typeDes: 'Dining',
      website: 'https://legacy.example.com',
    );

    expect(item.id, 'B002');
    expect(item.name, 'Legacy POI');
    expect(item.address, 'Legacy address');
    expect(item.shopId, 'shop-2');
    expect(item.indoor.floorName, 'F2');
    expect(item.children.single.name, 'Legacy Sub POI');
    expect(item.toJson()['subPois'], isNotEmpty);
  });

  test('AmapSearchException carries platform error details', () {
    const exception = AmapSearchException(
      code: 'AMAP_SEARCH_ERROR',
      message: 'Invalid user key',
      details: <String, Object?>{'errorCode': 1002},
    );

    expect(exception.code, 'AMAP_SEARCH_ERROR');
    expect(exception.details, <String, Object?>{'errorCode': 1002});
    expect(exception.toString(), contains('Invalid user key'));
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
      'country': '中国',
      'province': '上海市',
      'city': '',
      'cityCode': '021',
      'district': '黄浦区',
      'adCode': '310101',
      'township': '南京东路街道',
      'townCode': '310101002000',
      'neighborhood': '人民广场',
      'building': 'Sample building',
      'streetNumber': <String, Object?>{
        'street': '南京东路',
        'number': '1号',
        'location': <String, Object?>{
          'latitude': 31.2305,
          'longitude': 121.4738,
        },
        'sdkDistanceMeters': 12,
        'direction': '东',
      },
    },
    'pois': <Object?>[_samplePoiJson()],
    'aois': <Object?>[
      <String, Object?>{
        'id': 'AOI1',
        'name': 'Sample AOI',
        'adCode': '310101',
        'center': <String, Object?>{'latitude': 31.2304, 'longitude': 121.4737},
        'areaSquareMeters': 1000,
      },
    ],
    'roads': <Object?>[
      <String, Object?>{
        'id': 'R1',
        'name': '南京东路',
        'location': <String, Object?>{
          'latitude': 31.2304,
          'longitude': 121.4737,
        },
        'sdkDistanceMeters': 5,
        'direction': '北',
      },
    ],
    'roadIntersections': <Object?>[
      <String, Object?>{
        'firstRoadId': 'R1',
        'firstRoadName': '南京东路',
        'secondRoadId': 'R2',
        'secondRoadName': '西藏中路',
        'location': <String, Object?>{
          'latitude': 31.2304,
          'longitude': 121.4737,
        },
        'sdkDistanceMeters': 8,
        'direction': '南',
      },
    ],
  };
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
