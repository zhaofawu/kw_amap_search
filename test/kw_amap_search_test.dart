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
    AmapKeywordSearchQuery query,
  ) async {
    lastKeywordQuery = query;
    return results;
  }

  @override
  Future<List<SearchResultItem>> searchNearby(
    AmapAroundSearchQuery query,
  ) async {
    lastAroundQuery = query;
    return results;
  }

  @override
  Future<List<SearchResultItem>> searchKeyword({
    required String keyword,
    String city = '',
    String types = '',
    int pageSize = 20,
    int pageNum = 1,
  }) {
    return searchByKeyword(
      AmapKeywordSearchQuery(
        keyword: keyword,
        city: city,
        types: types,
        pageSize: pageSize,
        pageNum: pageNum,
      ),
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
      ),
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
      );

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
  });

  test('SearchResultItem exposes clean names and legacy aliases', () {
    final item = SearchResultItem.fromJson(_samplePoiJson());

    expect(item.id, 'B001');
    expect(item.name, 'Sample POI');
    expect(item.address, 'Sample address');
    expect(item.location.latitude, 31.2304);
    expect(item.location.longitude, 121.4737);
    expect(item.indoor.floorName, 'F1');
    expect(item.entryLocation.latitude, 31.2);
    expect(item.exitLocation.longitude, 121.5);
    expect(item.photos.single.url, 'https://example.com/photo.jpg');
    expect(item.openingHours.openTime, '09:00-18:00');
    expect(item.children.single.location.longitude, 121.4738);

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
